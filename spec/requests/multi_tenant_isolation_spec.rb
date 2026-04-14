require "rails_helper"

RSpec.describe "Multi-tenant isolation", type: :request do
  def login_as(user, password: "password123")
    post sessions_path, params: { email: user.email, password: password }
    expect(response).to have_http_status(:found)
  end

  it "prevents identity drift: header keeps showing user's real community when community_slug is spoofed" do
    a = create_community(name: "Community A", abbreviation: "CA", slug: "community-a")
    b = create_community(name: "Community B", abbreviation: "CB", slug: "community-b")

    user = User.create!(name: "Buyer", email: TestData.unique_email(prefix: "buyer"), password: "password123",
                        password_confirmation: "password123", community: a)
    seller = User.create!(name: "Seller", email: TestData.unique_email(prefix: "seller"), password: "password123",
                          password_confirmation: "password123", community: b)
    Product.create!(name: "B Item", description: "A very good item from B.", price: 10, seller: seller)

    login_as(user)
    get community_products_path(community_slug: b.slug)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("#{user.name} (#{a.abbreviation})")
    expect(response.body).not_to include("(#{b.abbreviation})</span>")
  end

  it "supports cross-community search results" do
    a = create_community(name: "Community A", abbreviation: "CA", slug: "community-a-2")
    b = create_community(name: "Community B", abbreviation: "CB", slug: "community-b-2")

    user = User.create!(name: "Buyer", email: TestData.unique_email(prefix: "buyer"), password: "password123",
                        password_confirmation: "password123", community: a)
    seller_a = User.create!(name: "SellerA", email: TestData.unique_email(prefix: "seller_a"), password: "password123",
                            password_confirmation: "password123", community: a)
    seller_b = User.create!(name: "SellerB", email: TestData.unique_email(prefix: "seller_b"), password: "password123",
                            password_confirmation: "password123", community: b)

    Product.create!(name: "MacBook Pro", description: "MacBook laptop from A.", price: 100, seller: seller_a,
                    community: a)
    Product.create!(name: "MacBook Air", description: "MacBook laptop from B.", price: 90, seller: seller_b,
                    community: b)

    login_as(user)
    get community_products_path(community_slug: a.slug), params: { query: "MacBook" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("MacBook Pro")
    expect(response.body).to include("MacBook Air")
  end

  it "blocks cross-community listing writes (GET new / POST create) and emits an audit event" do
    a = create_community(name: "Community A", abbreviation: "CA", slug: "community-a-3")
    b = create_community(name: "Community B", abbreviation: "CB", slug: "community-b-3")

    user = User.create!(name: "Seller", email: TestData.unique_email(prefix: "seller"), password: "password123",
                        password_confirmation: "password123", community: a)

    login_as(user)
    expect do
      get new_community_listing_path(community_slug: b.slug)
    end.to change(AuditEvent, :count).by(1)
    expect(response).to have_http_status(:forbidden)

    expect do
      post community_listings_path(community_slug: b.slug),
           params: { product: { name: "X", description: "A long enough description.", price: 10,
                                condition: "Like New" } }
    end.to change(AuditEvent, :count).by(1)
    expect(response).to have_http_status(:forbidden)
  end

  it "enforces per-community listing quota" do
    a = create_community(name: "Community A", abbreviation: "CA", slug: "community-a-4")
    a.update!(max_active_products_per_user: 1)

    user = User.create!(name: "Seller", email: TestData.unique_email(prefix: "seller"), password: "password123",
                        password_confirmation: "password123", community: a)
    Product.create!(name: "Existing", description: "Existing active listing.", price: 10, seller: user)

    login_as(user)
    post community_listings_path(community_slug: a.slug),
         params: { product: { name: "New", description: "A long enough description.", price: 10,
                              condition: "Like New" } }

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "scopes messages by conversation + community, supports after_id filtering, and blocks outsiders" do
    a = create_community(name: "Community A", abbreviation: "CA", slug: "community-a-5")
    b = create_community(name: "Community B", abbreviation: "CB", slug: "community-b-5")

    buyer = User.create!(name: "Buyer", email: TestData.unique_email(prefix: "buyer"), password: "password123",
                         password_confirmation: "password123", community: a)
    seller = User.create!(name: "Seller", email: TestData.unique_email(prefix: "seller"), password: "password123",
                          password_confirmation: "password123", community: b)
    product = Product.create!(name: "Item", description: "A long enough description.", price: 10, seller: seller)
    conversation = Conversation.create!(product: product, buyer: buyer, seller: seller)

    m1 = Message.create!(conversation: conversation, sender: buyer, content: "Hello 1")
    m2 = Message.create!(conversation: conversation, sender: seller, content: "Hello 2")

    login_as(buyer)
    get community_conversation_messages_path(community_slug: b.slug, conversation_id: conversation.id),
        params: { after_id: m1.id },
        headers: { "ACCEPT" => "application/json" }

    expect(response).to have_http_status(:ok)
    payload = response.parsed_body
    expect(payload.pluck("id")).to eq([m2.id])
    expect(payload.first["sender_name"]).to include("(#{seller.community.abbreviation})")

    post community_conversation_messages_path(community_slug: b.slug, conversation_id: conversation.id),
         params: { message: { content: "" } },
         headers: { "ACCEPT" => "application/json" }
    expect(response).to have_http_status(:unprocessable_content)

    post community_conversation_messages_path(community_slug: b.slug, conversation_id: conversation.id),
         params: { message: { content: "ok" } },
         headers: { "ACCEPT" => "application/json" }
    expect(response).to have_http_status(:ok)

    outsider = User.create!(name: "Outsider", email: TestData.unique_email(prefix: "outsider"), password: "password123",
                            password_confirmation: "password123", community: a)
    login_as(outsider)
    get community_conversation_messages_path(community_slug: b.slug, conversation_id: conversation.id),
        headers: { "ACCEPT" => "application/json" }
    expect(response).to have_http_status(:forbidden)
  end

  it "blocks conversation show for non-participants" do
    b = create_community(name: "Community B", abbreviation: "CB", slug: "community-b-6")
    outsider_community = create_community(name: "Community A", abbreviation: "CA", slug: "community-a-6")

    buyer = User.create!(name: "Buyer", email: TestData.unique_email(prefix: "buyer"), password: "password123",
                         password_confirmation: "password123", community: outsider_community)
    seller = User.create!(name: "Seller", email: TestData.unique_email(prefix: "seller"), password: "password123",
                          password_confirmation: "password123", community: b)
    product = Product.create!(name: "Item", description: "A long enough description.", price: 10, seller: seller)
    conversation = Conversation.create!(product: product, buyer: buyer, seller: seller)

    outsider = User.create!(name: "Outsider", email: TestData.unique_email(prefix: "outsider"), password: "password123",
                            password_confirmation: "password123", community: outsider_community)
    login_as(outsider)
    get community_conversation_path(community_slug: b.slug, id: conversation.id)

    expect(response).to have_http_status(:forbidden)
  end
end
