require "rails_helper"

RSpec.describe Listing, type: :model do
  let(:seller) do
    User.create!(
      name: "Seller",
      email: "listing-seller@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  it "is valid with title, description, price, and user" do
    listing = Listing.new(title: "iPhone 13", description: "Good condition", price: 2800, user: seller)
    expect(listing).to be_valid
  end

  it "calculates 10% deposit amount" do
    listing = Listing.new(title: "iPhone 13", description: "Good condition", price: 2999, user: seller)
    expect(listing.deposit_amount.to_f).to eq(299.9)
  end
end
