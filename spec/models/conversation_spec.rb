require "rails_helper"

RSpec.describe Conversation, type: :model do
  let(:seller) { User.create!(name: "Seller", email: TestData.unique_email(prefix: "seller"), password: "password123") }
  let(:buyer)  { User.create!(name: "Buyer",  email: TestData.unique_email(prefix: "buyer"),  password: "password123") }
  let(:product) do
    Product.create!(name: "MacBook", description: "Great laptop in perfect condition",
                    price: 3000, seller: seller)
  end

  describe "validations" do
    it "is valid with product, buyer and seller" do
      conv = described_class.new(product: product, buyer: buyer, seller: seller)
      expect(conv).to be_valid
    end

    it "is invalid when buyer equals seller" do
      conv = described_class.new(product: product, buyer: seller, seller: seller)
      expect(conv).not_to be_valid
      expect(conv.errors[:buyer_id]).to be_present
    end

    it "is invalid without a product" do
      conv = described_class.new(buyer: buyer, seller: seller)
      expect(conv).not_to be_valid
    end
  end

  describe "associations" do
    it "belongs to product" do
      assoc = described_class.reflect_on_association(:product)
      expect(assoc.macro).to eq(:belongs_to)
    end

    it "has many messages" do
      assoc = described_class.reflect_on_association(:messages)
      expect(assoc.macro).to eq(:has_many)
    end
  end

  describe ".for_user" do
    it "returns conversations where user is buyer or seller" do
      conv = Conversation.create!(product: product, buyer: buyer, seller: seller)
      expect(Conversation.for_user(buyer)).to include(conv)
      expect(Conversation.for_user(seller)).to include(conv)
    end
  end
end
