require "rails_helper"

RSpec.describe Payments::Providers::Stripe do
  subject(:provider) { described_class.new }

  around do |example|
    old_secret = ENV.fetch("STRIPE_SECRET_KEY", nil)
    old_webhook = ENV.fetch("STRIPE_WEBHOOK_SECRET", nil)
    old_host = ENV.fetch("APP_HOST", nil)
    ENV["APP_HOST"] = "http://test.host"
    example.run
  ensure
    ENV["STRIPE_SECRET_KEY"] = old_secret
    ENV["STRIPE_WEBHOOK_SECRET"] = old_webhook
    ENV["APP_HOST"] = old_host
  end

  def stub_stripe!(session_url: "https://stripe.test/checkout", session_id: "cs_test_123")
    stub_const("Stripe", build_stripe_stub(session_url:, session_id:))
  end

  def build_stripe_stub(session_url:, session_id:)
    stripe_mod = Module.new
    stripe_mod.singleton_class.attr_accessor :api_key
    stripe_mod.const_set(:Checkout, build_checkout_stub(session_url:, session_id:))
    stripe_mod.const_set(:Webhook, build_webhook_stub)
    stripe_mod
  end

  def build_checkout_stub(session_url:, session_id:)
    checkout_mod = Module.new
    checkout_mod.const_set(:Session, build_checkout_session_class(session_url:, session_id:))
    checkout_mod
  end

  def build_checkout_session_class(session_url:, session_id:)
    klass = Class.new
    klass.define_singleton_method(:create) do |params|
      @last_params = params
      Struct.new(:id, :url).new(session_id, session_url)
    end
    klass.define_singleton_method(:last_params) { @last_params }
    klass
  end

  def build_webhook_stub
    webhook_mod = Module.new
    webhook_mod.define_singleton_method(:construct_event) do |payload, signature, secret|
      raise "missing signature" if signature.to_s.empty?
      raise "missing payload" if payload.to_s.empty?
      raise "missing secret" if secret.to_s.empty?

      {
        "id" => "evt_123",
        "type" => "checkout.session.completed",
        "data" => { "object" => { "id" => "cs_123", "amount_total" => 1234 } }
      }
    end
    webhook_mod
  end

  it "creates a checkout session and returns redirect_url + reference" do
    stub_stripe!
    ENV["STRIPE_SECRET_KEY"] = "sk_test"

    community = create_community(name: "Community A", abbreviation: "CA", slug: "community-a-stripe")
    seller = User.create!(name: "Seller", email: TestData.unique_email(prefix: "seller"),
                          password: "password123", password_confirmation: "password123", community: community)
    buyer = User.create!(name: "Buyer", email: TestData.unique_email(prefix: "buyer"),
                         password: "password123", password_confirmation: "password123", community: create_community)
    product = Product.create!(name: "Item", description: "A long enough description.", price: 10, seller: seller)
    tx = Transaction.create!(product: product, buyer: buyer, seller: seller, status: :in_progress)
    payment = Payment.create!(transaction_id: tx.id, amount: 12.34, provider: "stripe", status: :pending)

    result = provider.create_checkout(payment: payment)
    expect(result[:redirect_url]).to eq("https://stripe.test/checkout")
    expect(result[:provider_reference]).to eq("cs_test_123")
    expect(result[:callback_token]).to be_nil

    params = Stripe::Checkout::Session.last_params
    expect(params[:success_url]).to include("/#{community.slug}/payments/#{payment.id}")
    expect(params[:cancel_url]).to include("/#{community.slug}/payments/#{payment.id}")
  end

  it "verifies webhook payload and normalizes event" do
    stub_stripe!
    ENV["STRIPE_SECRET_KEY"] = "sk_test"
    ENV["STRIPE_WEBHOOK_SECRET"] = "whsec_test"

    request = double(:request, raw_post: "{}", headers: { "Stripe-Signature" => "sig" })
    normalized = provider.verify_webhook(request)

    expect(normalized["event_id"]).to eq("evt_123")
    expect(normalized["provider_reference"]).to eq("cs_123")
    expect(normalized["amount"]).to eq("12.34")
    expect(normalized["outcome"]).to eq("succeeded")
  end

  it "raises when STRIPE_SECRET_KEY is missing" do
    stub_stripe!
    ENV["STRIPE_SECRET_KEY"] = ""

    expect { provider.create_checkout(payment: double(:payment, amount: 1)) }.to raise_error(KeyError)
  end

  it "raises when STRIPE_WEBHOOK_SECRET is missing" do
    stub_stripe!
    ENV["STRIPE_SECRET_KEY"] = "sk_test"
    ENV["STRIPE_WEBHOOK_SECRET"] = ""

    request = double(:request, raw_post: "{}", headers: { "Stripe-Signature" => "sig" })
    expect { provider.verify_webhook(request) }.to raise_error(KeyError)
  end

  it "raises when payment amount is not positive" do
    stub_stripe!
    ENV["STRIPE_SECRET_KEY"] = "sk_test"

    community = create_community(name: "Community A", abbreviation: "CA", slug: "community-a-stripe-2")
    payment = double(:payment, id: 1, amount: 0, product_transaction: double(:tx, community: community))
    expect { provider.create_checkout(payment: payment) }.to raise_error(ArgumentError)
  end
end
