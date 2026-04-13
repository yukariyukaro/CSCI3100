module Payments
  module Providers
    class Stripe < Provider
      def name
        "stripe"
      end

      def create_checkout(payment:)
        raise NotImplementedError
      end

      def verify_webhook(request)
        # In a real app, we'd verify the signature here.
        # For now, just return the parameters.
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
