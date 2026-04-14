require "rails_helper"

RSpec.describe "Products", type: :request do
  let(:community) { default_community }
  let(:seller) do
    User.create!(
      name: "Seller",
      email: TestData.unique_email(prefix: "seller"),
      community: community,
      password: "password123",
      password_confirmation: "password123"
    )
  end

  describe "GET /products" do
    before do
      Product.create!(name: "MacBook Pro", description: "Apple laptop", price: 1000, seller: seller,
                      created_at: 2.days.ago)
      Product.create!(name: "iPhone 15", description: "Apple smartphone", price: 800, seller: seller,
                      created_at: 1.day.ago)
      Product.create!(name: "二手iPhone 13", description: "9成新，无划痕，电池健康度良好", price: 500, seller: seller,
                      created_at: 3.days.ago)
    end

    it "returns all products when no query is provided" do
      get community_products_path(community_slug: community.slug)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("MacBook Pro")
      expect(response.body).to include("iPhone 15")
    end

    it "returns matching products when a query is provided (>= 2 chars)" do
      get community_products_path(community_slug: community.slug), params: { query: "MacBook" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("MacBook Pro")
      expect(response.body).not_to include("iPhone 15")
    end

    it "requires minimum 2 characters for search" do
      get community_products_path(community_slug: community.slug), params: { query: "a" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("too_short").or include("Please enter at least 2 characters")
      expect(response.body).not_to include("MacBook Pro")
    end

    it "supports Chinese/English mixed search" do
      get community_products_path(community_slug: community.slug), params: { query: "二手iPhone" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("二手iPhone 13")
    end

    it "sorts by price ascending" do
      get community_products_path(community_slug: community.slug), params: { sort: "price_asc" }
      # Just verifying it doesn't crash and returns OK for now
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /products/autocomplete" do
    before do
      Product.create!(name: "MacBook Pro 14", description: "Apple laptop", price: 2000, seller: seller)
      Product.create!(name: "MacBook Pro 16", description: "Apple laptop", price: 2500, seller: seller)
      Product.create!(name: "MacBook Air", description: "Apple laptop", price: 1000, seller: seller)
      Product.create!(name: "iPhone 15", description: "Apple smartphone", price: 800, seller: seller)
      # Duplicate name for testing uniq
      Product.create!(name: "MacBook Air", description: "Another Air", price: 900, seller: seller)
    end

    it "returns empty array when query is less than 2 characters" do
      get autocomplete_community_products_path(community_slug: community.slug), params: { query: "M" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])
    end

    it "returns matching product names uniquely, limited to 8" do
      # Create more to test limit
      (1..6).each do |i|
        Product.create!(name: "MacBook Model #{i}", description: "Good condition Apple laptop.", price: 100,
                        seller: seller)
      end

      get autocomplete_community_products_path(community_slug: community.slug), params: { query: "MacBook" }
      expect(response).to have_http_status(:ok)

      json_response = response.parsed_body
      expect(json_response.length).to eq(8)

      # Check uniqueness (there were two "MacBook Air")
      expect(json_response.count("MacBook Air")).to eq(1)
    end

    it "caches the results" do
      allow(Rails.cache).to receive(:fetch).and_call_original
      get autocomplete_community_products_path(community_slug: community.slug), params: { query: "Mac" }
      expect(Rails.cache).to have_received(:fetch).with("autocomplete_#{community.slug}_mac", expires_in: 5.minutes)
    end
  end

  describe "GET /products/:id" do
    it "returns the product details without AI summary if description is too short" do
      product = Product.create!(name: "MacBook Pro", description: "Apple laptop", price: 1000,
                                seller: seller, ai_summary_status: "skipped")
      get community_product_path(community_slug: community.slug, id: product)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("MacBook Pro")
      expect(response.body).to include("Apple laptop")
      expect(response.body).to include("Ask AI about this")
    end

    it "does not auto-trigger summary generation on page load" do
      product = Product.create!(
        name: "Manual Trigger Product",
        description: "Long enough description for manual AI summary trigger check.",
        price: 500,
        seller: seller,
        ai_summary_status: "pending",
        community: community
      )

      # We check that call_sync is NOT called on ANY instance
      expect_any_instance_of(Ai::Summarizer).not_to receive(:call_sync)
      # Also mock call so it doesn't actually hit the API
      allow_any_instance_of(Ai::Summarizer).to receive(:call)
      
      get community_product_path(community_slug: community.slug, id: product)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ask AI about this")
    end

    it "renders the AI summary card if the product has a summary" do
      product = Product.create!(name: "Used iPhone", description: "Long long desc", price: 500,
                                seller: seller, ai_summary: "✅ Good condition", ai_summary_status: "completed",
                                ai_last_question: "Is this worth the price?", community: community)
      get community_product_path(community_slug: community.slug, id: product)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AI Answer")
      expect(response.body).to include("Good condition")
      expect(response.body).to include("Your last question")
      expect(response.body).to include("Is this worth the price?")
    end
  end

  describe "POST /products/:id/ask_ai_about_this" do
    it "retries summary generation and redirects back to product" do
      product = Product.create!(
        name: "Retry Product",
        description: "Long enough description to trigger retry summary generation.",
        price: 88,
        seller: seller,
        ai_summary_status: "failed"
      )

      allow_any_instance_of(Ai::Summarizer).to receive(:call_sync).and_return(
        {
          status: "ok",
          ai_summary: "Great choice",
          message: "AI answered your question.",
          question: "Is this durable?"
        }
      )

      post ask_ai_about_this_community_product_path(community_slug: community.slug, id: product), params: { question: "Is this durable?" }
      expect(response).to redirect_to(community_product_path(community_slug: community.slug, id: product))
    end

    it "returns turbo stream response for turbo requests" do
      product = Product.create!(
        name: "Turbo Product",
        description: "Long enough description to trigger summary generation for turbo stream response.",
        price: 120,
        seller: seller,
        ai_summary_status: "pending"
      )

      allow_any_instance_of(Ai::Summarizer).to receive(:call_sync).and_return(
        {
          status: "failed",
          ai_summary: nil,
          message: "AI took too long to respond. Please try again.",
          question: "What is good here?"
        }
      )

      post ask_ai_about_this_community_product_path(community_slug: community.slug, id: product),
           params: { question: "What is good here?" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("turbo-stream")
      expect(response.body).to include("AI took too long to respond")
    end

    it "keeps the user question in the turbo response after failure" do
      product = Product.create!(
        name: "Question Preserve Product",
        description: "Long enough description to test question preservation in turbo response.",
        price: 120,
        seller: seller,
        ai_summary_status: "pending"
      )

      allow_any_instance_of(Ai::Summarizer).to receive(:call_sync).and_return(
        {
          status: "failed",
          ai_summary: nil,
          message: "AI is temporarily unavailable. Please try again.",
          question: "Does it include charger?"
        }
      )

      post ask_ai_about_this_community_product_path(community_slug: community.slug, id: product),
           params: { question: "Does it include charger?" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.body).to include("Does it include charger?")
    end
  end

  describe "GET /api/products/:id/ai_summary" do
    it "returns summary status with metadata fields" do
      product = Product.create!(
        name: "API Test Product",
        description: "Long enough description for summary metadata endpoint.",
        price: 100,
        seller: seller,
        ai_summary_status: "pending",
        ai_summary_requested_at: Time.current,
        community: community
      )

      get ai_summary_api_community_product_path(community_slug: community.slug, id: product)
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["ai_summary_status"]).to eq("pending")
      expect(body).to have_key("ai_summary_requested_at")
      expect(body).to have_key("ai_last_question")
      expect(body).to have_key("updated_at")
    end
  end

  describe "Product status flow" do
    let!(:seller) do
      User.create!(
        name: "Seller",
        email: TestData.unique_email(prefix: "seller"),
        community: community,
        password: "password123",
        password_confirmation: "password123"
      )
    end

    let!(:buyer) do
      User.create!(
        name: "Buyer",
        email: TestData.unique_email(prefix: "buyer"),
        community: create_community,
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
      post reserve_community_product_path(community_slug: product.community.slug, id: product)
      expect(response).to redirect_to(new_session_path)
    end

    it "allows buyer to reserve an active product and creates a transaction" do
      login_as(buyer)

      expect do
        post reserve_community_product_path(community_slug: product.community.slug, id: product)
      end.to change(Transaction, :count).by(1)

      expect(response).to redirect_to(community_product_path(community_slug: product.community.slug, id: product))
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
      post reserve_community_product_path(community_slug: product.community.slug, id: product)
      expect(response).to redirect_to(community_product_path(community_slug: product.community.slug, id: product))
      product.reload
      expect(product.sale_status).to eq("active")
      expect(Transaction.count).to eq(0)
    end

    it "allows buyer to cancel reservation and keeps history" do
      login_as(buyer)
      post reserve_community_product_path(community_slug: product.community.slug, id: product)
      product.reload
      tx = product.active_transaction
      expect(tx).to be_present

      delete cancel_reservation_community_product_path(community_slug: product.community.slug, id: product)
      expect(response).to redirect_to(community_product_path(community_slug: product.community.slug, id: product))
      product.reload
      tx.reload

      expect(product.sale_status).to eq("active")
      expect(tx.status).to eq("cancelled")
    end

    it "allows seller to mark sold and completes transaction" do
      login_as(buyer)
      post reserve_community_product_path(community_slug: product.community.slug, id: product)
      product.reload
      tx = product.active_transaction
      expect(tx).to be_present

      login_as(seller)
      patch mark_sold_community_product_path(community_slug: product.community.slug, id: product)
      expect(response).to redirect_to(community_product_path(community_slug: product.community.slug, id: product))
      product.reload
      tx.reload

      expect(product.sale_status).to eq("sold")
      expect(tx.status).to eq("completed")
      expect(tx.completed_at).to be_present
    end
  end
end
