module Payments
  class Gateway
    def call
      { provider: ProviderFactory.instance.name }
    end
  end
end
