require "rails_helper"

RSpec.describe Payments::ProviderFactory, type: :model do
  def with_env(vars)
    snapshot = env_snapshot(vars.keys)
    apply_env(vars)
    yield
  ensure
    restore_env(snapshot)
  end

  def env_snapshot(keys)
    keys.index_with { |k| ENV.key?(k) ? ENV[k] : :__missing__ }
  end

  def apply_env(vars)
    vars.each { |k, v| ENV[k] = v }
  end

  def restore_env(snapshot)
    snapshot.each { |k, v| v == :__missing__ ? ENV.delete(k) : ENV[k] = v }
  end

  def in_production
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
    yield
  end

  it "rejects fake provider in production unless explicitly allowed" do
    in_production do
      with_env({ "PAYMENT_PROVIDER" => "fake", "ALLOW_FAKE_PAYMENT_PROVIDER" => "false" }) do
        expect { described_class.instance }.to raise_error(RuntimeError, /Fake payment provider is not allowed/)
      end
    end
  end

  it "allows fake provider in production when explicitly allowed" do
    in_production do
      with_env({ "PAYMENT_PROVIDER" => "fake", "ALLOW_FAKE_PAYMENT_PROVIDER" => "true" }) do
        expect(described_class.instance.name).to eq("fake")
      end
    end
  end
end
