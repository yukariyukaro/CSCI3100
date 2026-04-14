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
  end
end
