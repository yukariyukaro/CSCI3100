class Escrow < ApplicationRecord
  belongs_to :listing
  belongs_to :buyer, class_name: "User"
  belongs_to :seller, class_name: "User"

  has_many :payments, dependent: :nullify

  enum :status, {
    pending: 0,
    deposited: 1,
    completed: 2,
    cancelled: 3,
    disputed: 4
  }

  validates :amount, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(status: %i[pending deposited]) }

  def self.find_or_create_for!(listing:, buyer:)
    escrow = find_or_initialize_by(listing:, buyer:)
    escrow.seller = listing.user
    escrow.amount = listing.deposit_amount

    if escrow.new_record? || escrow.cancelled? || escrow.completed?
      escrow.status = :pending
      escrow.stripe_payment_intent_id = nil
    end

    escrow.save! if escrow.changed?
    escrow
  end

  def confirm_deposit_paid!(payment_intent_id)
    update!(stripe_payment_intent_id: payment_intent_id, status: :deposited)
    listing.update!(status: :reserved)
  end

  def complete_transaction!
    transaction do
      update!(status: :completed)
      listing.update!(status: :sold)
      create_payment!(
        user: seller,
        transaction_type: :release,
        status: :succeeded,
        payment_intent_id: stripe_payment_intent_id
      )
    end
  end

  def cancel_by_buyer!
    transaction do
      update!(status: :cancelled)
      listing.update!(status: :available)
      create_payment!(
        user: seller,
        transaction_type: :penalty,
        status: :succeeded,
        payment_intent_id: stripe_payment_intent_id
      )
    end
  end

  def cancel_by_seller_with_refund!(payment_intent_id: stripe_payment_intent_id)
    transaction do
      update!(status: :cancelled)
      listing.update!(status: :available)
      create_payment!(
        user: buyer,
        transaction_type: :refund,
        status: :refunded,
        payment_intent_id:
      )
    end
  end

  private

  def create_payment!(user:, transaction_type:, status:, payment_intent_id:)
    Payment.create!(
      user:,
      escrow: self,
      provider: "escrow",
      transaction_type:,
      amount:,
      status:,
      stripe_payment_intent_id: payment_intent_id
    )
  end
end
