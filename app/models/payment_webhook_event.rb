class PaymentWebhookEvent < ApplicationRecord
  belongs_to :payment, optional: true

  validates :provider, presence: true
  validates :event_id, presence: true, uniqueness: { scope: :provider }

  def self.record(provider:, event_id:)
    id = event_id.to_s
    return true if id.blank?

    create!(provider: provider, event_id: id)
    true
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    false
  end
end
