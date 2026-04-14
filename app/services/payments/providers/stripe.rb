module Payments
  module Providers
    class Stripe < Provider
      def name
        "stripe"
      end

      def create_checkout(payment:)
        configure!

        amount_cents = amount_cents_for(payment)
        session = ::Stripe::Checkout::Session.create(checkout_session_params(payment, amount_cents))

        {
          redirect_url: session.url,
          provider_reference: session.id,
          callback_token: nil
        }
      end

      def verify_webhook(request)
        configure!

        event = construct_event(request)
        normalize_event(event)
      end

      def extract_amount(payload)
        BigDecimal(payload.fetch("amount").to_s)
      end

      def extract_reference(payload)
        payload.fetch("provider_reference").to_s
      end

      private

      def configure!
        key = ENV.fetch("STRIPE_SECRET_KEY", "").to_s
        raise KeyError, "missing STRIPE_SECRET_KEY" if key.blank?

        ::Stripe.api_key = key
      end

      def amount_cents_for(payment)
        amount_cents = (BigDecimal(payment.amount.to_s) * 100).to_i
        raise ArgumentError, "amount must be positive" if amount_cents <= 0

        amount_cents
      end

      def checkout_session_params(payment, amount_cents)
        {
          mode: "payment",
          line_items: line_items_for(payment, amount_cents),
          metadata: metadata_for(payment),
          success_url: payment_success_url(payment),
          cancel_url: payment_cancel_url(payment)
        }
      end

      def line_items_for(payment, amount_cents)
        [line_item_for(payment, amount_cents)]
      end

      def metadata_for(payment)
        { payment_id: payment.id }
      end

      def line_item_for(payment, amount_cents)
        {
          quantity: 1,
          price_data: {
            currency: "hkd",
            unit_amount: amount_cents,
            product_data: { name: "Order ##{payment.id}" }
          }
        }
      end

      def construct_event(request)
        payload = request.raw_post.to_s
        signature = request.headers["Stripe-Signature"].to_s
        secret = ENV.fetch("STRIPE_WEBHOOK_SECRET", "").to_s
        raise KeyError, "missing STRIPE_WEBHOOK_SECRET" if secret.blank?

        ::Stripe::Webhook.construct_event(payload, signature, secret).to_h
      end

      def normalize_event(event)
        object = event.fetch("data").fetch("object")
        event_type = event.fetch("type").to_s

        {
          "event_id" => event.fetch("id").to_s,
          "provider_reference" => object.fetch("id").to_s,
          "amount" => amount_from_object(object),
          "outcome" => outcome_for(event_type)
        }.compact
      end

      def amount_from_object(object)
        amount_cents = object["amount_total"] || object["amount"]
        return if amount_cents.blank?

        (BigDecimal(amount_cents.to_s) / 100).to_s("F")
      end

      def outcome_for(event_type)
        return "cancelled" if %w[checkout.session.expired checkout.session.async_payment_failed].include?(event_type)

        "succeeded"
      end

      def payment_success_url(payment)
        community_slug = payment.product_transaction.community.slug
        Rails.application.routes.url_helpers.community_payment_url(community_slug:, id: payment.id, host: app_host)
      end

      def payment_cancel_url(payment)
        community_slug = payment.product_transaction.community.slug
        Rails.application.routes.url_helpers.community_payment_url(community_slug:, id: payment.id, host: app_host)
      end

      def app_host
        ENV.fetch("APP_HOST", "").presence || "http://localhost:3000"
      end
    end
  end
end
