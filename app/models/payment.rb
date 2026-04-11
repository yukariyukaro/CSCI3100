<<<<<<< HEAD
class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :escrow, optional: true

  enum :transaction_type, { deposit: 0, release: 1, penalty: 2, refund: 3 }
  enum :status, { pending: 0, succeeded: 1, failed: 2, refunded: 3 }

  validates :amount, presence: true, numericality: { greater_than: 0 }
end
=======
class Payment < ApplicationRecord
  belongs_to :product_transaction, class_name: "Transaction", foreign_key: :transaction_id, inverse_of: :payments
  belongs_to :resolved_by, class_name: "User", optional: true

  enum :status, {
    pending: 0,
    succeeded: 1,
    failed: 2,
    cancelled: 3,
    manual_intervention_required: 4
  }

  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :provider, presence: true
  validates :provider_reference, uniqueness: { scope: :provider }, allow_blank: true
  validates :callback_token, presence: true, if: -> { provider == "fake" }
end
>>>>>>> main
