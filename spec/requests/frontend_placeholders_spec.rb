require "rails_helper"

RSpec.describe "Frontend placeholders", type: :request do
  it "renders home page" do
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("CUHK Marketplace")
  end

  it "renders products pages" do
    get products_path
    expect(response).to have_http_status(:ok)

    seller = User.create!(
      name: "Seller",
      email: TestData.unique_email(prefix: "seller"),
      password: "password123",
      password_confirmation: "password123"
    )
    product = Product.create!(name: "Test Product", description: "Placeholder desc", seller: seller, price: 12.34)
    get product_path(product)
    expect(response).to have_http_status(:ok)
  end

  it "renders chats pages" do
    get chats_path
    expect(response).to have_http_status(:ok)
    get chat_path(1)
    expect(response).to have_http_status(:ok)
  end

  it "requires login for payments pages" do
    get payments_path
    expect(response).to redirect_to(new_session_path)

    seller = User.create!(
      name: "Seller",
      email: TestData.unique_email(prefix: "seller"),
      password: "password123",
      password_confirmation: "password123"
    )
    buyer = User.create!(
      name: "Buyer",
      email: TestData.unique_email(prefix: "buyer"),
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
    expect(response).to redirect_to(root_path)

    post transaction_payments_path(tx)
    expect(response).to have_http_status(:found)
    expect(response.location).to include("/payments/")
    expect(response.location).to include("/fake")

    payment = Payment.last
    get payments_path
    expect(response).to have_http_status(:ok)
    get payment_path(payment)
    expect(response).to have_http_status(:ok)
  end

  it "renders listings index and protects listing creation when logged out" do
    get listings_path
    expect(response).to have_http_status(:ok)

    get new_listing_path
    expect(response).to redirect_to(new_session_path)

    post listings_path
    expect(response).to redirect_to(new_session_path)
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
    post users_path,
         params: {
           user: {
             name: "Alice",
             email: email,
             password: "password123",
             password_confirmation: "password123"
           }
         }

    expect(response).to redirect_to(root_path)
    expect(User.find_by(email: email)).to be_present
  end

  it "logs in with valid credentials and logs out" do
    email = TestData.unique_email(prefix: "alice")
    user = User.create!(
      name: "Alice",
      email: email,
      password: "password123",
      password_confirmation: "password123"
    )

    post sessions_path, params: { email: user.email, password: "password123" }
    expect(response).to redirect_to(root_path)
    expect(session[:user_id]).to eq(user.id)

    delete session_path(user.id)
    expect(response).to redirect_to(root_path)
    expect(session[:user_id]).to be_nil
  end

  it "rejects login with invalid credentials" do
    email = TestData.unique_email(prefix: "alice")
    User.create!(
      name: "Alice",
      email: email,
      password: "password123",
      password_confirmation: "password123"
    )

    post sessions_path, params: { email: email, password: "wrong-password" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(session[:user_id]).to be_nil
  end
end
