require "rails_helper"

RSpec.describe "Frontend placeholders", type: :request do
  it "renders home page" do
    get root_path
    expect(response).to have_http_status(:found)
    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Choose Your Community")
  end

  it "renders products pages" do
    community = default_community
    seller = User.create!(
      name: "Seller",
      email: TestData.unique_email(prefix: "seller"),
      community: community,
      password: "password123",
      password_confirmation: "password123"
    )
    product = Product.create!(name: "Test Product", description: "Placeholder desc", seller: seller, price: 12.34)
    get community_products_path(community_slug: community.slug)
    expect(response).to have_http_status(:ok)

    get community_product_path(community_slug: community.slug, id: product)
    expect(response).to have_http_status(:ok)
  end

  it "redirects legacy chats pages" do
    get "/chats"
    expect(response).to have_http_status(:not_found)

    get "/chats/1"
    expect(response).to have_http_status(:not_found)
  end

  it "supports payments flow pages" do
    community = default_community
    get community_payments_path(community_slug: community.slug)
    expect(response).to redirect_to(new_session_path)

    seller = User.create!(
      name: "Seller",
      email: TestData.unique_email(prefix: "seller"),
      community: community,
      password: "password123",
      password_confirmation: "password123"
    )
    buyer_community = create_community
    buyer = User.create!(
      name: "Buyer",
      email: TestData.unique_email(prefix: "buyer"),
      community: buyer_community,
      password: "password123",
      password_confirmation: "password123"
    )

    product = Product.create!(
      name: "Test Product",
      description: "Placeholder desc",
      price: 12.34,
      seller_id: seller.id,
      sale_status: :pending
    )
    tx = Transaction.create!(product: product, buyer: buyer, seller: seller, status: :in_progress)

    post sessions_path, params: { email: buyer.email, password: "password123" }
    expect(response).to redirect_to(community_products_path(community_slug: buyer.community.slug))

    post community_transaction_payments_path(community_slug: product.community.slug, transaction_id: tx.id)
    expect(response).to have_http_status(:found)
    expect(response.location).to include("/payments/")
    expect(response.location).to include("/fake")

    payment = Payment.last
    get community_payments_path(community_slug: product.community.slug)
    expect(response).to have_http_status(:ok)
    get community_payment_path(community_slug: product.community.slug, id: payment)
    expect(response).to have_http_status(:ok)
  end

  it "renders listings pages and supports create placeholder" do
    community = default_community
    # Unauthenticated requests are redirected to login
    get community_listings_path(community_slug: community.slug)
    expect(response).to redirect_to(new_session_path)
    get new_community_listing_path(community_slug: community.slug)
    expect(response).to redirect_to(new_session_path)
    post community_listings_path(community_slug: community.slug)
    expect(response).to redirect_to(new_session_path)

    # Authenticated user can access listings pages
    seller = User.create!(
      name: "Seller",
      email: TestData.unique_email(prefix: "seller"),
      community: community,
      password: "password123",
      password_confirmation: "password123"
    )
    post sessions_path, params: { email: seller.email, password: "password123" }

    get community_listings_path(community_slug: community.slug)
    expect(response).to have_http_status(:ok)
    get new_community_listing_path(community_slug: community.slug)
    expect(response).to have_http_status(:ok)
  end

  it "renders login page" do
    get new_session_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Login")
  end

  it "renders registration page" do
    get new_user_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Sign Up")
  end

  it "registers a new user successfully" do
    email = TestData.unique_email(prefix: "alice")
    community = default_community
    post users_path,
         params: {
           user: {
             name: "Alice",
             email: email,
             community_id: community.id,
             password: "password123",
             password_confirmation: "password123"
           }
         }

    expect(response).to redirect_to(community_products_path(community_slug: community.slug))
    expect(User.find_by(email: email)).to be_present
  end

  it "logs in with valid credentials and logs out" do
    email = TestData.unique_email(prefix: "alice")
    community = default_community
    user = User.create!(
      name: "Alice",
      email: email,
      community: community,
      password: "password123",
      password_confirmation: "password123"
    )

    post sessions_path, params: { email: user.email, password: "password123" }
    expect(response).to redirect_to(community_products_path(community_slug: community.slug))
    expect(session[:user_id]).to eq(user.id)

    delete session_path(user.id)
    expect(response).to redirect_to(communities_path)
    expect(session[:user_id]).to be_nil
  end

  it "rejects login with invalid credentials" do
    email = TestData.unique_email(prefix: "alice")
    community = default_community
    User.create!(
      name: "Alice",
      email: email,
      community: community,
      password: "password123",
      password_confirmation: "password123"
    )

    post sessions_path, params: { email: email, password: "wrong-password" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(session[:user_id]).to be_nil
  end
end
