class Product < ApplicationRecord
  include PgSearch::Model
  include ProductSearch

  belongs_to :seller, class_name: "User", inverse_of: :products
  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_fill: [512, 512], saver: { quality: 82 }
  end
  has_many :transactions, dependent: :destroy, inverse_of: :product
  has_one :active_transaction,
          -> { where(status: :in_progress) },
          class_name: "Transaction",
          inverse_of: :product
  has_many :conversations, dependent: :destroy

  enum :sale_status, { active: 0, pending: 1, sold: 2, unlisted: 3 }

  validates :name, presence: true
  validates :description, presence: true, length: { minimum: 10 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :image_content_type_and_size, if: -> { image.attached? }

  scope :recent_first, -> { order(created_at: :desc) }
  scope :by_status,    ->(status) { where(sale_status: status) }
  scope :by_seller,    ->(user_id) { where(seller_id: user_id) }
  scope :visible,      -> { where.not(sale_status: :unlisted) }
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
    self.ai_last_question = nil
    self.ai_summary_status = "pending"
    self.ai_summary_requested_at = nil
  end

  def image_content_type_and_size
    allowed_types = %w[image/jpeg image/png]
    errors.add(:image, "must be a JPEG or PNG file") unless allowed_types.include?(image.content_type)

    return unless image.byte_size > 5.megabytes

    errors.add(:image, "must be smaller than 5MB")
  end
end
