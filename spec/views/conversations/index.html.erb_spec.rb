require "rails_helper"

RSpec.describe "conversations/index.html.erb", type: :view do
  let(:community) { default_community }
  let(:seller) do
    User.create!(name: "Seller", email: TestData.unique_email(prefix: "seller"), password: "password123",
                 community: community)
  end
  let(:buyer) do
    User.create!(name: "Buyer", email: TestData.unique_email(prefix: "buyer"), password: "password123",
                 community: community)
  end
  let(:product) { Product.create!(name: "iPhone 14", description: "Good condition", seller: seller, price: 1000) }
  let(:conversation) { Conversation.create!(product: product, buyer: buyer, seller: seller) }

  before do
    current = buyer
    view.singleton_class.send(:define_method, :current_user) { current }
    Current.community = community
  end

  it "renders conversations list" do
    Message.create!(conversation: conversation, sender: buyer, content: "Hello from buyer")

    assign(:conversations, [conversation])
    render

    expect(rendered).to include("My Conversations")
    expect(rendered).to include("#{seller.name} (#{seller.community.abbreviation})")
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
