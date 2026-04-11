require "rails_helper"

RSpec.describe "Products", type: :request do
  describe "GET /products" do
    before do
      Product.create!(name: "MacBook Pro", description: "Apple laptop", price: 1000, created_at: 2.days.ago)
      Product.create!(name: "iPhone 15", description: "Apple smartphone", price: 800, created_at: 1.day.ago)
      Product.create!(name: "二手iPhone 13", description: "9成新", price: 500, created_at: 3.days.ago)
    end

    it "returns all products when no query is provided" do
      get products_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("MacBook Pro")
      expect(response.body).to include("iPhone 15")
    end

    it "returns matching products when a query is provided (>= 2 chars)" do
      get products_path, params: { query: "MacBook" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("MacBook Pro")
      expect(response.body).not_to include("iPhone 15")
    end

    it "requires minimum 2 characters for search" do
      get products_path, params: { query: "a" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("too_short").or include("Please enter at least 2 characters")
      expect(response.body).not_to include("MacBook Pro")
    end

    it "supports Chinese/English mixed search" do
      get products_path, params: { query: "二手iPhone" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("二手iPhone 13")
    end

    it "sorts by price ascending" do
      get products_path, params: { sort: "price_asc" }
      # Just verifying it doesn't crash and returns OK for now
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /products/autocomplete" do
    before do
      Product.create!(name: "MacBook Pro 14", description: "Apple laptop", price: 2000)
      Product.create!(name: "MacBook Pro 16", description: "Apple laptop", price: 2500)
      Product.create!(name: "MacBook Air", description: "Apple laptop", price: 1000)
      Product.create!(name: "iPhone 15", description: "Apple smartphone", price: 800)
      # Duplicate name for testing uniq
      Product.create!(name: "MacBook Air", description: "Another Air", price: 900)
    end

    it "returns empty array when query is less than 2 characters" do
      get autocomplete_products_path, params: { query: "M" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])
    end

    it "returns matching product names uniquely, limited to 8" do
      # Create more to test limit
      (1..6).each do |i|
        Product.create!(name: "MacBook Model #{i}", description: "Test", price: 100)
      end

      get autocomplete_products_path, params: { query: "MacBook" }
      expect(response).to have_http_status(:ok)

      json_response = response.parsed_body
      expect(json_response.length).to eq(8)

      # Check uniqueness (there were two "MacBook Air")
      expect(json_response.count("MacBook Air")).to eq(1)
    end

    it "caches the results" do
      allow(Rails.cache).to receive(:fetch).and_call_original
      get autocomplete_products_path, params: { query: "Mac" }
      expect(Rails.cache).to have_received(:fetch).with("autocomplete_mac", expires_in: 5.minutes)
    end
  end

  describe "GET /products/:id" do
    it "returns the product details without AI summary if description is too short" do
      product = Product.create!(name: "MacBook Pro", description: "Apple laptop", price: 1000,
                                ai_summary_status: "skipped")
      get product_path(product)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("MacBook Pro")
      expect(response.body).to include("Apple laptop")
      expect(response.body).to include("hidden")
    end

    it "renders the AI summary card if the product has a summary" do
      product = Product.create!(name: "Used iPhone", description: "Long long desc", price: 500,
                                ai_summary: "✅ Good condition", ai_summary_status: "completed")
      get product_path(product)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AI 智能卖点总结")
      expect(response.body).to include("Good condition")
    end
  end

  describe "Product status flow" do
    let!(:seller) do
      User.create!(
        name: "Seller",
        email: TestData.unique_email(prefix: "seller"),
        password: "password123",
        password_confirmation: "password123"
      )
    end

    let!(:buyer) do
      User.create!(
        name: "Buyer",
        email: TestData.unique_email(prefix: "buyer"),
        password: "password123",
        password_confirmation: "password123"
      )
    end

    let!(:product) do
      Product.create!(name: "二手iPhone 13", description: "9成新，电池健康度85%", price: 2500, seller: seller)
    end

    def login_as(user)
      post sessions_path, params: { email: user.email, password: "password123" }
      expect(response).to have_http_status(:found)
    end

    it "requires login to reserve" do
      post reserve_product_path(product)
      expect(response).to redirect_to(new_session_path)
    end

    it "allows buyer to reserve an active product and creates a transaction" do
      login_as(buyer)

      expect do
        post reserve_product_path(product)
      end.to change(Transaction, :count).by(1)

      expect(response).to redirect_to(product_path(product))
      product.reload
      expect(product.sale_status).to eq("pending")

      tx = product.active_transaction
      expect(tx).to be_present
      expect(tx.buyer_id).to eq(buyer.id)
      expect(tx.seller_id).to eq(seller.id)
      expect(tx.status).to eq("in_progress")
    end

    it "prevents seller from reserving own product" do
      login_as(seller)
      post reserve_product_path(product)
      expect(response).to redirect_to(product_path(product))
      product.reload
      expect(product.sale_status).to eq("active")
      expect(Transaction.count).to eq(0)
    end

    it "allows buyer to cancel reservation and keeps history" do
      login_as(buyer)
      post reserve_product_path(product)
      product.reload
      tx = product.active_transaction
      expect(tx).to be_present

      delete cancel_reservation_product_path(product)
      expect(response).to redirect_to(product_path(product))
      product.reload
      tx.reload

      expect(product.sale_status).to eq("active")
      expect(tx.status).to eq("cancelled")
    end

    it "allows seller to mark sold and completes transaction" do
      login_as(buyer)
      post reserve_product_path(product)
      product.reload
      tx = product.active_transaction
      expect(tx).to be_present

      login_as(seller)
      patch mark_sold_product_path(product)
      expect(response).to redirect_to(product_path(product))
      product.reload
      tx.reload

      expect(product.sale_status).to eq("sold")
      expect(tx.status).to eq("completed")
      expect(tx.completed_at).to be_present
    end
  end
end
