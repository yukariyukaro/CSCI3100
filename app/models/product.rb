class Product < ApplicationRecord
  include PgSearch::Model

  belongs_to :seller, class_name: "User", optional: true, inverse_of: :products
  has_many :transactions, dependent: :destroy, inverse_of: :product
  has_one :active_transaction,
          -> { where(status: :in_progress) },
          class_name: "Transaction",
          inverse_of: :product

  enum :sale_status, { active: 0, pending: 1, sold: 2 }

  validates :name, presence: true
  validates :description, presence: true

  scope :recent_first, -> { order(created_at: :desc) }
  scope :by_status,    ->(status) { where(sale_status: status) }
  scope :by_seller,    ->(user_id) { where(seller_id: user_id) }
  scope :for_sale,     -> { where(sale_status: %i[active pending]) }

  # Reset AI summary if the description changes
  before_update :reset_ai_summary, if: :description_changed?

  # Set up advanced search scope using pg_search
  pg_search_scope :advanced_search,
                  against: {
                    name: "A",        # Brand/Name weighting (Highest)
                    description: "B"  # Description weighting (Lower)
                  },
                  using: {
                    # Using 'simple' dictionary instead of 'english' to avoid aggressively
                    # stripping parts of non-English words, better for Chinese/English mix.
                    tsearch: { prefix: true, dictionary: "simple" },
                    trigram: { threshold: 0.1, word_similarity: true } # Typo tolerance
                  }

  def self.search(query)
    if query.present?
      advanced_search(query)
    else
      all
    end
  end

  def self.suggest(query)
    return [] if query.blank?

    # Change from prefix match (query%) to fuzzy match (%query%) to support
    # mid-string matches like "iPhone" in "二手iPhone"
    where("name ILIKE ?", "%#{sanitize_sql_like(query)}%")
      .select(:name)
      .distinct
      .limit(8)
      .pluck(:name)
  end

  def reserve_by(buyer)
    return false unless reservable_by?(buyer)

    with_lock { reserve_in_lock?(buyer) }
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    false
  end

  def cancel_reservation_by(actor)
    return false if actor.blank?

    with_lock { cancel_in_lock?(actor) }
  rescue ActiveRecord::RecordInvalid
    false
  end

  def mark_sold_by(actor)
    return false if actor.blank? || seller_id.blank? || seller_id != actor.id

    with_lock { mark_sold_in_lock? }
  rescue ActiveRecord::RecordInvalid
    false
  end

  private

  def reservable_by?(buyer)
    buyer.present? && seller_id.present? && seller_id != buyer.id
  end

  def reserve_in_lock?(buyer)
    return false unless active? && active_transaction.blank?

    update!(sale_status: :pending)
    transactions.create!(buyer: buyer, seller: seller, status: :in_progress)

    true
  end

  def cancel_in_lock?(actor)
    return false unless pending?

    tx = active_transaction
    return false if tx.blank? || [seller_id, tx.buyer_id].exclude?(actor.id)

    update!(sale_status: :active)
    tx.update!(status: :cancelled)

    true
  end

  def mark_sold_in_lock?
    return false unless pending?

    tx = active_transaction
    return false if tx.blank?

    update!(sale_status: :sold)
    tx.update!(status: :completed)

    true
  end

  def reset_ai_summary
    self.ai_summary = nil
    self.ai_summary_status = "pending"
    self.ai_summary_requested_at = nil
  end
end
