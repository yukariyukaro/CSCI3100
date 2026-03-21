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
    get product_path(1)
    expect(response).to have_http_status(:ok)
  end

  it "renders chats pages" do
    get chats_path
    expect(response).to have_http_status(:ok)
    get chat_path(1)
    expect(response).to have_http_status(:ok)
  end

  it "renders payments pages and supports create placeholder" do
    get payments_path
    expect(response).to have_http_status(:ok)
    get new_payment_path
    expect(response).to have_http_status(:ok)
    get payment_path(1)
    expect(response).to have_http_status(:ok)
    post payments_path
    expect(response).to redirect_to(payments_path)
  end

  it "renders listings pages and supports create placeholder" do
    get listings_path
    expect(response).to have_http_status(:ok)
    get new_listing_path
    expect(response).to have_http_status(:ok)
    post listings_path
    expect(response).to redirect_to(listings_path)
  end

  it "renders sessions placeholder and supports create and destroy" do
    get new_session_path
    expect(response).to have_http_status(:ok)
    post sessions_path
    expect(response).to redirect_to(root_path)
    delete session_path(1)
    expect(response).to redirect_to(root_path)
  end

  it "renders users pages" do
    get users_path
    expect(response).to have_http_status(:ok)
    get user_path(1)
    expect(response).to have_http_status(:ok)
  end
end
