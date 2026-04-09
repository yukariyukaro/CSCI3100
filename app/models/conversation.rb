class Conversation < ApplicationRecord
  belongs_to :product
  belongs_to :buyer,  class_name: "User", inverse_of: :buying_conversations
  belongs_to :seller, class_name: "User", inverse_of: :selling_conversations

  has_many :messages, dependent: :destroy
  validate :buyer_and_seller_must_differ

  scope :for_user, ->(user) { where("buyer_id = ? OR seller_id = ?", user.id, user.id) }
  scope :recent_first, -> { order(updated_at: :desc) }

  private

  def buyer_and_seller_must_differ
    return if buyer_id.blank? || seller_id.blank?

    errors.add(:buyer_id, "can't be the same as seller") if buyer_id == seller_id
  end
end
