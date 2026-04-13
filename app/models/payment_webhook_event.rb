class PaymentWebhookEvent < ApplicationRecord
  belongs_to :payment, optional: true

  validates :provider, presence: true
  validates :event_id, presence: true, uniqueness: { scope: :provider }
end
