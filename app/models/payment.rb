class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :escrow, optional: true

  enum :transaction_type, { deposit: 0, release: 1, penalty: 2, refund: 3 }
  enum :status, { pending: 0, succeeded: 1, failed: 2, refunded: 3 }

  validates :amount, presence: true, numericality: { greater_than: 0 }
end
