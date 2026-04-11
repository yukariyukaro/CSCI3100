require "rails_helper"

RSpec.describe Escrow, type: :model do
  let!(:seller) do
    User.create!(
      name: "Seller",
      email: "escrow-seller@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:buyer) do
    User.create!(
      name: "Buyer",
      email: "escrow-buyer@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:listing) do
    Listing.create!(
      title: "MacBook Air",
      description: "16GB / 512GB",
      price: 6000,
      user: seller
    )
  end

  it "creates escrow from listing and buyer" do
    escrow = described_class.find_or_create_for!(listing: listing, buyer: buyer)

    expect(escrow.buyer).to eq(buyer)
    expect(escrow.seller).to eq(seller)
    expect(escrow.amount.to_f).to eq(600.0)
    expect(escrow.status).to eq("pending")
  end

  it "forfeits deposit when buyer cancels" do
    escrow = described_class.find_or_create_for!(listing: listing, buyer: buyer)
    escrow.confirm_deposit_paid!("pi_123")

    expect do
      escrow.cancel_by_buyer!
    end.to change(Payment, :count).by(1)

    expect(escrow.reload.status).to eq("cancelled")
    expect(listing.reload.status).to eq("available")
    expect(Payment.last.transaction_type).to eq("penalty")
  end
end
