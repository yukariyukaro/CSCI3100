require "rails_helper"

RSpec.describe PaymentSettlement, type: :model do
  let(:seller) do
    User.create!(name: "Seller", email: TestData.unique_email(prefix: "seller"),
                 password: "password123", password_confirmation: "password123")
  end
  let(:buyer) do
    User.create!(name: "Buyer", email: TestData.unique_email(prefix: "buyer"),
                 password: "password123", password_confirmation: "password123")
  end
  let(:product) do
    Product.create!(name: "Laptop", description: "Good", price: 10.00, seller: seller, sale_status: :pending)
  end
  let(:tx) do
    Transaction.create!(product: product, buyer: buyer, seller: seller, status: :in_progress)
  end
  let(:payment) do
    Payment.create!(
      transaction_id: tx.id,
      amount: 10.00,
      provider: "fake",
      provider_reference: "fake_ref",
      callback_token: "tok_123",
      status: :pending
    )
  end

  it "settles successfully when amount matches and states are valid" do
    result = described_class.call(payment, provider_amount: "10.00")
    expect(result).to eq(true)
    expect(payment.reload).to be_succeeded
    expect(tx.reload).to be_completed
    expect(product.reload).to be_sold
  end

  it "marks manual_intervention_required when amount mismatches" do
    result = described_class.call(payment, provider_amount: "11.00")
    expect(result).to eq(false)
    expect(payment.reload).to be_manual_intervention_required
    expect(tx.reload).to be_in_progress
    expect(product.reload).to be_pending
  end

  it "marks manual_intervention_required when transaction is not in_progress" do
    tx.update!(status: :cancelled)
    result = described_class.call(payment, provider_amount: "10.00")
    expect(result).to eq(false)
    expect(payment.reload).to be_manual_intervention_required
    expect(product.reload).to be_pending
  end
end
