require "rails_helper"

RSpec.describe Payments::Provider do
  subject(:provider) { described_class.new }

  it "raises NotImplementedError for abstract methods" do
    expect { provider.name }.to raise_error(NotImplementedError)
    expect { provider.create_checkout(payment: double(:payment)) }.to raise_error(NotImplementedError)
    expect { provider.verify_webhook(double(:request)) }.to raise_error(NotImplementedError)
    expect { provider.extract_amount({}) }.to raise_error(NotImplementedError)
    expect { provider.extract_reference({}) }.to raise_error(NotImplementedError)
  end
end
