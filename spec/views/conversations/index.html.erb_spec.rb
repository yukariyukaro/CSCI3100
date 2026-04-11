require "rails_helper"

RSpec.describe "conversations/index.html.erb", type: :view do
  let(:seller) { User.create!(name: "Seller", email: "seller_view@example.com", password: "password123") }
  let(:buyer)  { User.create!(name: "Buyer", email: "buyer_view@example.com", password: "password123") }
  let(:product) { Product.create!(name: "iPhone 14", description: "Good condition", seller: seller) }
  let(:conversation) { Conversation.create!(product: product, buyer: buyer, seller: seller) }

  before do
    current = buyer
    view.singleton_class.send(:define_method, :current_user) { current }
  end

  it "renders conversations list" do
    Message.create!(conversation: conversation, sender: buyer, content: "Hello from buyer")

    assign(:conversations, [conversation])
    render

    expect(rendered).to include("My Conversations")
    expect(rendered).to include(seller.name)
    expect(rendered).to include(product.name)
    expect(rendered).to include("Hello from buyer")
  end

  it "renders empty state" do
    assign(:conversations, [])
    render

    expect(rendered).to include("No conversations yet.")
    expect(rendered).to include("Browse Products")
  end
end
