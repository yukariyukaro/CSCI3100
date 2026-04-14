module Payments
  module Providers
    class Fake < Provider
      def name
        "fake"
      end

      def create_checkout(payment:)
        provider_reference = "fake_#{SecureRandom.hex(10)}"
        callback_token = payment.callback_token.presence || SecureRandom.hex(16)

        {
          redirect_url: fake_redirect_url(payment, callback_token),
          provider_reference: provider_reference,
          callback_token: callback_token
        }
      end

      def verify_webhook(request)
        params = request.request_parameters.to_h
        reference = params["provider_reference"].to_s
        outcome = params.fetch("outcome", "succeeded").to_s
        params["event_id"] ||= if reference.present?
                                 "fake_evt_#{reference}_#{outcome}"
                               else
                                 "fake_evt_#{SecureRandom.hex(10)}"
                               end
        params
      end

      def extract_amount(payload)
        BigDecimal(payload.fetch("amount").to_s)
      end

      def extract_reference(payload)
        payload.fetch("provider_reference").to_s
      end

      def fake_redirect_url(payment, callback_token)
        community_slug = payment.product_transaction.community.slug
        Rails.application.routes.url_helpers.fake_community_payment_path(
          community_slug:,
          id: payment.id,
          token: callback_token
        )
      end
    end
  end
end
