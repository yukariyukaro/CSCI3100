class Product < ApplicationRecord
  include PgSearch::Model

  validates :name, presence: true
  validates :description, presence: true

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
end
