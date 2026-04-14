require "rails_helper"

RSpec.describe "Payments", type: :request do
  let(:community) { default_community }
  let!(:seller) do
    User.create!(
      name: "Seller",
      email: "request-seller@example.com",
      community: community,
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:buyer) do
    User.create!(
      name: "Buyer",
      email: "request-buyer@example.com",
      community: create_community,
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:product) do
    Product.create!(
      name: "Nintendo Switch",
      description: "Almost new",
      price: 2000,
      seller: seller,
      sale_status: :pending
    )
  end

  let!(:transaction) do
    Transaction.create!(
      product: product,
      buyer: buyer,
      seller: seller,
      status: :in_progress
    )
  end

  def login_as(user)
    post sessions_path, params: { email: user.email, password: "password123" }
    expect(response).to have_http_status(:found)
  end

  it "requires login for payment creation" do
    post community_transaction_payments_path(community_slug: product.community.slug, transaction_id: transaction.id)
    expect(response).to redirect_to(new_session_path)
  end

  it "creates payment and redirects to stripe checkout" do
    login_as(buyer)

    allow(Payments::ProviderFactory).to receive(:configured_provider_name).and_return("stripe")
    allow_any_instance_of(Payments::Providers::Stripe).to receive(:create_checkout).and_return(
      redirect_url: "https://checkout.stripe.com/test",
      provider_reference: "cs_test_123",
      callback_token: nil
    )

    expect do
      post community_transaction_payments_path(community_slug: product.community.slug, transaction_id: transaction.id)
    end.to change(Payment, :count).by(1)

    expect(response).to redirect_to("https://checkout.stripe.com/test")
    payment = Payment.last
    expect(payment.provider).to eq("stripe")
    expect(payment.provider_reference).to eq("cs_test_123")
    expect(payment.amount).to eq(2000)
  end

  it "handles webhook successfully" do
    payment = Payment.create!(
      transaction_id: transaction.id,
      amount: 2000,
      provider: "stripe",
      provider_reference: "cs_test_123",
      status: :pending
    )

    allow(Payments::ProviderFactory).to receive(:configured_provider_name).and_return("stripe")
    allow_any_instance_of(Payments::Providers::Stripe).to receive(:verify_webhook).and_return(
      "event_id" => "evt_test_1",
      "provider_reference" => "cs_test_123",
      "amount" => "2000.00"
    )

    post webhook_payments_path, params: {}

    expect(response).to have_http_status(:ok)
    expect(payment.reload.status).to eq("succeeded")
    expect(transaction.reload.status).to eq("completed")
    expect(product.reload.sale_status).to eq("sold")
  end

  it "treats repeated stripe webhook events as idempotent" do
    payment = Payment.create!(
      transaction_id: transaction.id,
      amount: 2000,
      provider: "stripe",
      provider_reference: "cs_test_123",
      status: :pending
    )

    allow(Payments::ProviderFactory).to receive(:configured_provider_name).and_return("stripe")
    allow_any_instance_of(Payments::Providers::Stripe).to receive(:verify_webhook).and_return(
      "event_id" => "evt_test_repeat",
      "provider_reference" => "cs_test_123",
      "amount" => "2000.00"
    )

    post webhook_payments_path, params: {}
    expect(response).to have_http_status(:ok)
    expect(payment.reload.status).to eq("succeeded")

    post webhook_payments_path, params: {}
    expect(response).to have_http_status(:ok)
    expect(payment.reload.status).to eq("succeeded")
  end

  it "returns bad_request when stripe webhook signature verification fails" do
    allow(Payments::ProviderFactory).to receive(:configured_provider_name).and_return("stripe")
    allow_any_instance_of(Payments::Providers::Stripe).to receive(:verify_webhook).and_raise(Stripe::SignatureVerificationError.new(
                                                                                               "bad", "sig"
                                                                                             ))

    post webhook_payments_path, params: {}

    expect(response).to have_http_status(:bad_request)
  end
end
