require "rails_helper"

RSpec.describe Message, type: :model do
  let(:seller)  { User.create!(name: "Seller", email: "seller2@example.com", password: "password123") }
  let(:buyer)   { User.create!(name: "Buyer",  email: "buyer2@example.com",  password: "password123") }
  let(:product) do
    Product.create!(name: "iPhone", description: "Mint condition iPhone with original box",
                    price: 2000, seller: seller)
  end
  let(:conversation) { Conversation.create!(product: product, buyer: buyer, seller: seller) }

  describe "validations" do
    it "is valid with content, conversation and sender" do
      msg = described_class.new(conversation: conversation, sender: buyer, content: "Hello!")
      expect(msg).to be_valid
    end

    it "is invalid without content" do
      msg = described_class.new(conversation: conversation, sender: buyer)
      expect(msg).not_to be_valid
      expect(msg.errors[:content]).to be_present
    end

    it "is invalid without a sender" do
      msg = described_class.new(conversation: conversation, content: "Hi")
      expect(msg).not_to be_valid
    end
  end

  describe "associations" do
    it "belongs to conversation" do
      assoc = described_class.reflect_on_association(:conversation)
      expect(assoc.macro).to eq(:belongs_to)
    end

    it "belongs to sender (User)" do
      assoc = described_class.reflect_on_association(:sender)
      expect(assoc.macro).to eq(:belongs_to)
      expect(assoc.options[:class_name]).to eq("User")
    end
  end
end
