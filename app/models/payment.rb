class Payment < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :escrow, optional: true
  belongs_to :product_transaction,
             class_name: "Transaction",
             foreign_key: "transaction_id",
             inverse_of: :payments,
             optional: true

  enum :transaction_type, { deposit: 0, release: 1, penalty: 2, refund: 3 }
  enum :status,
       {
         pending: 0,
         succeeded: 1,
         failed: 2,
         refunded: 3,
         manual_intervention_required: 4
       }

  validates :amount, presence: true, numericality: { greater_than: 0 }
end
