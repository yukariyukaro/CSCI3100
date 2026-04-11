module Payments
  class StripePaymentService
    def initialize(user)
      @user = user
      Stripe.api_key = ENV.fetch("STRIPE_SECRET_KEY", nil)
    end

    def create_deposit_payment(amount:, escrow:)
      payment_intent = Stripe::PaymentIntent.create(
        amount: (amount * 100).to_i,
        currency: "hkd",
        automatic_payment_methods: { enabled: true },
        metadata: {
          user_id: @user.id,
          user_email: @user.email,
          listing_id: escrow.listing_id,
          escrow_id: escrow.id,
          purpose: "escrow_deposit"
        }
      )

      {
        success: true,
        payment_intent_id: payment_intent.id,
        client_secret: payment_intent.client_secret
      }
    rescue Stripe::StripeError => e
      { success: false, error: e.message }
    end

    def retrieve_payment_intent(payment_intent_id)
      Stripe::PaymentIntent.retrieve(payment_intent_id)
    end

    def refund_payment(payment_intent_id)
      Stripe::Refund.create(payment_intent: payment_intent_id)
    end
  end
end
