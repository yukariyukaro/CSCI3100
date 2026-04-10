class Transaction < ApplicationRecord
  belongs_to :product, inverse_of: :transactions
  belongs_to :buyer, class_name: "User", inverse_of: :bought_transactions
  belongs_to :seller, class_name: "User", inverse_of: :sold_transactions
  has_many :payments, dependent: :destroy, inverse_of: :product_transaction

  enum :status, { pending: 0, in_progress: 1, completed: 2, reviewed: 3, cancelled: 4, expired: 5 }

  validate :buyer_and_seller_must_differ

  before_update :set_completed_at, if: :will_save_change_to_status?

  scope :by_status,    ->(st)      { where(status: st) }
  scope :recent_first, ->          { order(created_at: :desc) }
  scope :for_user,     ->(user_id) { where("buyer_id = ? OR seller_id = ?", user_id, user_id) }

  private

  def buyer_and_seller_must_differ
    return if buyer_id.blank? || seller_id.blank?

    errors.add(:buyer_id, "can't be the same as seller") if buyer_id == seller_id
  end

  def set_completed_at
    self.completed_at = Time.current if status == "completed"
  end
end
