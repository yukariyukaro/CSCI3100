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
        raise NotImplementedError
      end

      def extract_amount(payload)
        raise NotImplementedError
      end

      def extract_reference(payload)
        raise NotImplementedError
      end
    end
  end
end
