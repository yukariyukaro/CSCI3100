class Community < ApplicationRecord
  has_many :users, dependent: :restrict_with_exception
  has_many :products, dependent: :restrict_with_exception
  has_many :conversations, dependent: :restrict_with_exception
  has_many :transactions, dependent: :restrict_with_exception
  has_many :audit_events, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: true
  validates :abbreviation, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :max_active_products_per_user, numericality: { only_integer: true, greater_than: 0 }

  before_validation :normalize_slug

  after_save do
    Rails.cache.delete("community/#{slug_before_last_save}") if saved_change_to_slug?
  end

  def self.fetch_by_slug!(slug)
    Rails.cache.fetch("community/#{slug}", expires_in: 1.hour) do
      find_by!(slug: slug)
    end
  end

  def to_param
    slug
  end

  private

  def normalize_slug
    self.slug = slug.to_s.strip.presence || name.to_s.parameterize
  end
end
