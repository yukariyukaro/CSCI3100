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
          redirect_url: Rails.application.routes.url_helpers.fake_payment_path(payment, token: callback_token),
          provider_reference: provider_reference,
          callback_token: callback_token
        }
      end

      def verify_webhook(request)
        request.request_parameters.to_h
      end

      def extract_amount(payload)
        BigDecimal(payload.fetch("amount").to_s)
      end

      def extract_reference(payload)
        payload.fetch("provider_reference").to_s
      end
    end
  end
end
