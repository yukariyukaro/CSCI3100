# filepath: spec/models/transaction_spec.rb
require "rails_helper"

RSpec.describe Transaction, type: :model do
  let(:seller) do
    User.create!(name: "Seller", email: "seller@example.com",
                 password: "password123", password_confirmation: "password123")
  end
  let(:buyer) do
    User.create!(name: "Buyer", email: "buyer@example.com",
                 password: "password123", password_confirmation: "password123")
  end
  let(:product) do
    Product.create!(name: "iPhone 14", description: "Good condition", seller: seller)
  end

  describe "validations" do
    it "is valid with product, buyer, and seller" do
      transaction = described_class.new(
        product: product,
        buyer: buyer,
        seller: seller,
        status: :pending
      )
      expect(transaction).to be_valid
    end

    it "is invalid without a product" do
      transaction = described_class.new(buyer: buyer, seller: seller, status: :pending)
      expect(transaction).not_to be_valid
    end

    it "is invalid without a buyer" do
      transaction = described_class.new(product: product, seller: seller, status: :pending)
      expect(transaction).not_to be_valid
    end

    it "is invalid without a seller" do
      transaction = described_class.new(product: product, buyer: buyer, status: :pending)
      expect(transaction).not_to be_valid
    end

    it "is invalid when buyer and seller are the same user" do
      transaction = described_class.new(
        product: product,
        buyer: seller,
        seller: seller,
        status: :pending
      )
      expect(transaction).not_to be_valid
    end
  end

  describe "status enum" do
    it "defaults to pending status" do
      transaction = described_class.create!(product: product, buyer: buyer, seller: seller)
      expect(transaction.status).to eq("pending")
    end

    it "can transition to in_progress" do
      transaction = described_class.create!(
        product: product, buyer: buyer, seller: seller, status: :pending
      )
      transaction.in_progress!
      expect(transaction.reload.status).to eq("in_progress")
    end

    it "can transition to completed" do
      transaction = described_class.create!(
        product: product, buyer: buyer, seller: seller, status: :in_progress
      )
      transaction.completed!
      expect(transaction.reload.status).to eq("completed")
    end

    it "can transition to reviewed" do
      transaction = described_class.create!(
        product: product, buyer: buyer, seller: seller, status: :completed
      )
      transaction.reviewed!
      expect(transaction.reload.status).to eq("reviewed")
    end
  end

  describe "associations" do
    it "belongs to product" do
      transaction = described_class.create!(
        product: product, buyer: buyer, seller: seller, status: :pending
      )
      expect(transaction.product).to eq(product)
    end

    it "belongs to buyer (User)" do
      transaction = described_class.create!(
        product: product, buyer: buyer, seller: seller, status: :pending
      )
      expect(transaction.buyer).to eq(buyer)
    end

    it "belongs to seller (User)" do
      transaction = described_class.create!(
        product: product, buyer: buyer, seller: seller, status: :pending
      )
      expect(transaction.seller).to eq(seller)
    end
  end

  describe "scopes" do
    before do
      @t1 = described_class.create!(
        product: product, buyer: buyer, seller: seller, status: :pending
      )
      other_product = Product.create!(name: "MacBook", description: "Laptop", seller: buyer)
      @t2 = described_class.create!(
        product: other_product, buyer: seller, seller: buyer, status: :completed
      )
    end

    describe ".by_status" do
      it "returns transactions with matching status" do
        results = described_class.by_status(:pending)
        expect(results).to include(@t1)
        expect(results).not_to include(@t2)
      end
    end

    describe ".recent_first" do
      it "orders by created_at descending" do
        results = described_class.recent_first
        expect(results.first.id).to eq(@t2.id)
        expect(results.last.id).to eq(@t1.id)
      end
    end

    describe ".for_user" do
      it "returns transactions where user is buyer" do
        results = described_class.for_user(buyer.id)
        expect(results).to include(@t1)
      end

      it "returns transactions where user is seller" do
        results = described_class.for_user(seller.id)
        expect(results).to include(@t1)
      end

      it "returns all transactions involving the user (as buyer or seller)" do
        results = described_class.for_user(buyer.id)
        expect(results).to include(@t1)
        expect(results).to include(@t2)
      end
    end
  end
end
