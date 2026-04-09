class Conversation < ApplicationRecord
  belongs_to :product
  belongs_to :buyer,  class_name: "User", foreign_key: "buyer_id"
  belongs_to :seller, class_name: "User", foreign_key: "seller_id"

  has_many :messages, dependent: :destroy

  validates :product_id, :buyer_id, :seller_id, presence: true
  validate :buyer_and_seller_must_differ

  scope :for_user, ->(user) { where("buyer_id = ? OR seller_id = ?", user.id, user.id) }
  scope :recent_first, -> { order(updated_at: :desc) }

  private

  def buyer_and_seller_must_differ
    return if buyer_id.blank? || seller_id.blank?

    errors.add(:buyer_id, "can't be the same as seller") if buyer_id == seller_id
  end
end
