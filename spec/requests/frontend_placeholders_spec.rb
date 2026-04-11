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

    product = Product.create!(name: "Test Product", description: "Placeholder desc")
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

    get new_payment_path
    expect(response).to redirect_to(new_session_path)
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
    post users_path,
         params: {
           user: {
             name: "Alice",
             email: "alice@example.com",
             password: "password123",
             password_confirmation: "password123"
           }
         }

    expect(response).to redirect_to(root_path)
    expect(User.find_by(email: "alice@example.com")).to be_present
  end

  it "logs in with valid credentials and logs out" do
    user = User.create!(
      name: "Alice",
      email: "alice@example.com",
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
    User.create!(
      name: "Alice",
      email: "alice@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    post sessions_path, params: { email: "alice@example.com", password: "wrong-password" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(session[:user_id]).to be_nil
  end
end
