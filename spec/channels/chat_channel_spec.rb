require "rails_helper"

RSpec.describe ChatChannel, type: :channel do
  let(:seller) do
    User.create!(name: "Seller", email: TestData.unique_email(prefix: "seller"), password: "password123",
                 community: default_community)
  end
  let(:buyer) do
    User.create!(name: "Buyer", email: TestData.unique_email(prefix: "buyer"), password: "password123",
                 community: default_community)
  end
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
        expect(subscription).to have_stream_from("conversation_#{conversation.id}")
      end

      it "subscribes and streams for the seller" do
        stub_connection current_user: seller
        subscribe conversation_id: conversation.id
        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_from("conversation_#{conversation.id}")
      end
    end

    context "when user is NOT a participant" do
      it "rejects the subscription" do
        outsider = User.create!(name: "Outsider", email: TestData.unique_email(prefix: "outsider"),
                                password: "password123", community: default_community)
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
