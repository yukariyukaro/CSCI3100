require "rails_helper"

RSpec.describe "conversations/show.html.erb", type: :view do
  let(:seller) { User.create!(name: "Seller", email: TestData.unique_email(prefix: "seller"), password: "password123") }
  let(:buyer)  { User.create!(name: "Buyer", email: TestData.unique_email(prefix: "buyer"),  password: "password123") }
  let(:product) { Product.create!(name: "Laptop", description: "Works well", seller: seller) }
  let(:conversation) { Conversation.create!(product: product, buyer: buyer, seller: seller) }
  let(:message) { Message.create!(conversation: conversation, sender: buyer, content: "Is this still available?") }

  before do
    current = buyer
    view.singleton_class.send(:define_method, :current_user) { current }
    assign(:conversation, conversation)
    assign(:messages, [message])
  end

  it "renders chat room" do
    render

    expect(rendered).to include("data-controller=\"chat\"")
    expect(rendered).to include("data-chat-conversation-id-value=\"#{conversation.id}\"")
    expect(rendered).to include("data-chat-current-user-id-value=\"#{buyer.id}\"")
    expect(rendered).to include("data-chat-target=\"status\"")

    expect(rendered).to include("Back")
    expect(rendered).to include("Send")
    expect(rendered).to include(seller.name)
    expect(rendered).to include(product.name)
    expect(rendered).to include(message.content)
  end
end
