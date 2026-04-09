class Product < ApplicationRecord
  include PgSearch::Model

  belongs_to :seller, class_name: "User", inverse_of: :products, optional: true
  # Renamed from :transaction to avoid conflict with ActiveRecord's built-in #transaction method
  has_one :sale, class_name: "Transaction", dependent: :destroy

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

  private

  def reset_ai_summary
    self.ai_summary = nil
    self.ai_summary_status = "pending"
    self.ai_summary_requested_at = nil
  end
end
