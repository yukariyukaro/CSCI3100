require "rails_helper"

RSpec.describe "Payments", type: :request do
  let!(:seller) do
    User.create!(
      name: "Seller",
      email: "request-seller@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:buyer) do
    User.create!(
      name: "Buyer",
      email: "request-buyer@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:listing) do
    Listing.create!(
      title: "Nintendo Switch",
      description: "Almost new",
      price: 2000,
      user: seller
    )
  end

  def login_as(user)
    post sessions_path, params: { email: user.email, password: "password123" }
    expect(response).to have_http_status(:found)
  end

  it "requires login for new payment" do
    get new_listing_payment_path(listing)
    expect(response).to redirect_to(new_session_path)
  end

  it "creates payment record after Stripe payment intent succeeds" do
    login_as(buyer)

    allow_any_instance_of(Payments::StripePaymentService).to receive(:create_deposit_payment).and_return(
      success: true,
      payment_intent_id: "pi_test_success",
      client_secret: "cs_test_secret"
    )

    allow_any_instance_of(Payments::StripePaymentService).to receive(:retrieve_payment_intent).and_return(
      double(status: "succeeded")
    )

    get new_listing_payment_path(listing)
    escrow = Escrow.find_by(listing: listing, buyer: buyer)

    expect do
      post listing_payments_path(listing), params: { escrow_id: escrow.id, payment_intent_id: "pi_test_success" }
    end.to change(Payment, :count).by(1)

    expect(response).to redirect_to(payment_path(Payment.last))
    expect(escrow.reload.status).to eq("deposited")
    expect(listing.reload.status).to eq("reserved")
  end
end
