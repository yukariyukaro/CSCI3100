require "rails_helper"

RSpec.describe Payment, type: :model do
  let(:seller) do
    User.create!(name: "Seller", email: TestData.unique_email(prefix: "seller"),
                 password: "password123", password_confirmation: "password123", community: default_community)
  end
  let(:buyer) do
    User.create!(name: "Buyer", email: TestData.unique_email(prefix: "buyer"),
                 password: "password123", password_confirmation: "password123", community: default_community)
  end
  let(:product) do
    Product.create!(name: "Camera", description: "Good condition, barely used.", price: 99.99, seller: seller,
                    sale_status: :pending)
  end
  let(:tx) do
    Transaction.create!(product: product, buyer: buyer, seller: seller, status: :in_progress)
  end

  it "is valid with amount, provider, and callback_token for fake provider" do
    payment = described_class.new(
      transaction_id: tx.id,
      amount: 99.99,
      status: :pending,
      provider: "fake",
      callback_token: "tok_123"
    )
    expect(payment).to be_valid
  end

  it "requires callback_token for fake provider" do
    payment = described_class.new(
      transaction_id: tx.id,
      amount: 99.99,
      status: :pending,
      provider: "fake"
    )
    expect(payment).not_to be_valid
  end

  it "does not require callback_token for non-fake provider" do
    payment = described_class.new(
      transaction_id: tx.id,
      amount: 99.99,
      status: :pending,
      provider: "stripe"
    )
    expect(payment).to be_valid
  end

  it "supports manual_intervention_required status" do
    payment = described_class.create!(
      transaction_id: tx.id,
      amount: 99.99,
      provider: "fake",
      callback_token: "tok_123",
      status: :manual_intervention_required
    )
    expect(payment.status).to eq("manual_intervention_required")
  end
end
