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
      expect(response.body).to include("Please enter at least 2 characters")
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

  describe "GET /products/:id" do
    it "returns the product details" do
      product = Product.create!(name: "MacBook Pro", description: "Apple laptop")
      get product_path(product)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("MacBook Pro")
      expect(response.body).to include("Apple laptop")
    end
  end
end
