require "rails_helper"

RSpec.describe ChatChannel, type: :channel do
  let(:seller) { User.create!(name: "Seller", email: "cseller@example.com", password: "password123") }
  let(:buyer)  { User.create!(name: "Buyer",  email: "cbuyer@example.com",  password: "password123") }
  let(:product) do
    Product.create!(
      name: "Laptop", description: "High-performance laptop in excellent condition",
      price: 5000, seller: seller
    )
  end
  let(:conversation) { Conversation.create!(product: product, buyer: buyer, seller: seller) }

  describe "#subscribed" do
    context "when user is a participant" do
      it "subscribes and streams for the buyer" do
        stub_connection current_user: buyer
        subscribe conversation_id: conversation.id
        expect(subscription).to be_confirmed
        expect(streams).to include("conversation_#{conversation.id}")
      end

      it "subscribes and streams for the seller" do
        stub_connection current_user: seller
        subscribe conversation_id: conversation.id
        expect(subscription).to be_confirmed
        expect(streams).to include("conversation_#{conversation.id}")
      end
    end

    context "when user is NOT a participant" do
      it "rejects the subscription" do
        outsider = User.create!(name: "Outsider", email: "outsider@example.com", password: "password123")
        stub_connection current_user: outsider
        subscribe conversation_id: conversation.id
        expect(subscription).to be_rejected
      end
    end

    context "when conversation does not exist" do
      it "rejects the subscription" do
        stub_connection current_user: buyer
        subscribe conversation_id: 0
        expect(subscription).to be_rejected
      end
    end
  end
end
