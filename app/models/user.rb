class User < ApplicationRecord
  has_secure_password

  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_fill: [96, 96], saver: { quality: 80 }
  end
  has_many :products, class_name: "Product", foreign_key: "seller_id", dependent: :destroy, inverse_of: :seller
  has_many :bought_transactions,
           class_name: "Transaction",
           foreign_key: "buyer_id",
           dependent: :destroy,
           inverse_of: :buyer
  has_many :sold_transactions,
           class_name: "Transaction",
           foreign_key: "seller_id",
           dependent: :destroy,
           inverse_of: :seller

  validates :name,  presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validate  :avatar_content_type_and_size, if: -> { avatar.attached? }

  before_validation :normalize_email

  def avatar_url
    if avatar.attached?
      Rails.application.routes.url_helpers.url_for(avatar)
    else
      "/default-avatar.png"
    end
  end

  def sold_count
    sold_transactions.completed.count
  end

  def positive_reviews_count
    0 # placeholder — review module not yet implemented
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def avatar_content_type_and_size
    errors.add(:avatar, "must be a JPEG or PNG") unless avatar.content_type.in?(%w[image/jpeg image/png])
    return unless avatar.blob.byte_size > 5.megabytes

    errors.add(:avatar, "must be less than 5 MB")
  end
end
