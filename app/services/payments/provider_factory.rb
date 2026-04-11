module Payments
  class ProviderFactory
    def self.instance
      provider_name = configured_provider_name
      raise "Fake payment provider is not allowed in production" if Rails.env.production? && provider_name == "fake"

      build_provider(provider_name)
    end

    def self.configured_provider_name
      (Rails.application.config.x.payments&.provider || ENV.fetch("PAYMENT_PROVIDER", "fake")).to_s
    end
    private_class_method :configured_provider_name

    def self.build_provider(provider_name)
      case provider_name
      when "fake" then Providers::Fake.new
      when "stripe" then Providers::Stripe.new
      else raise "Unknown payment provider: #{provider_name}"
      end
    end
    private_class_method :build_provider
  end
end
