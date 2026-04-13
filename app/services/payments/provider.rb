module Payments
  class Provider
    def name
      raise NotImplementedError
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

    # rubocop:disable Naming/PredicateMethod
    def authorize_webhook!(_payment, _payload)
      true # Default implementation for providers that verify via signature (e.g. Stripe)
    end
    # rubocop:enable Naming/PredicateMethod
  end
end
