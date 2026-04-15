# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Listings", type: :request do
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

  # Helper: log in via session
  def log_in_as(user)
    post sessions_path, params: { email: user.email, password: "password123" }
  end

  # ─── Authentication guards ────────────────────────────────────────────────

  describe "GET /listings/new (authentication)" do
    context "when visitor is not logged in" do
      it "redirects to the login page" do
        get new_community_listing_path(community_slug: community.slug)
        expect(response).to redirect_to(new_session_path)
      end

      it "shows a flash message prompting login" do
        get new_community_listing_path(community_slug: community.slug)
        follow_redirect!
        expect(response.body).to include("log in").or include("Login").or include("sign in")
      end
    end

    context "when user is logged in" do
      before { log_in_as(seller) }

      it "returns 200 OK" do
        get new_community_listing_path(community_slug: community.slug)
        expect(response).to have_http_status(:ok)
      end

      it "renders the publication form" do
        get new_community_listing_path(community_slug: community.slug)
        expect(response.body).to include("form")
      end

      it "shows a name input field" do
        get new_community_listing_path(community_slug: community.slug)
        expect(response.body).to include('name="product[name]"').or include("Product Name").or include("product_name")
      end

      it "shows a description input field" do
        get new_community_listing_path(community_slug: community.slug)
        expect(response.body).to include('name="product[description]"').or include("product_description")
      end

      it "shows a price input field" do
        get new_community_listing_path(community_slug: community.slug)
        expect(response.body).to include('name="product[price]"').or include("product_price")
      end

      it "shows a condition select field" do
        get new_community_listing_path(community_slug: community.slug)
        expect(response.body)
          .to include('name="product[condition]"')
          .or include("product_condition")
          .or include("Like New")
      end

      it "shows an image upload field" do
        get new_community_listing_path(community_slug: community.slug)
        expect(response.body).to include('name="product[image]"').or include("product_image")
      end

      it "shows the Publish Product submit button" do
        get new_community_listing_path(community_slug: community.slug)
        expect(response.body).to include("Publish Product")
      end
    end
  end

  describe "POST /listings (authentication)" do
    context "when visitor is not logged in" do
      it "redirects to the login page" do
        post community_listings_path(community_slug: community.slug),
             params: { product: { name: "Test", description: "Long enough desc", price: 10 } }
        expect(response).to redirect_to(new_session_path)
      end

      it "does not create a product" do
        expect do
          post community_listings_path(community_slug: community.slug),
               params: { product: { name: "Test", description: "Long enough desc", price: 10 } }
        end.not_to change(Product, :count)
      end
    end
  end

  # ─── Valid submission ─────────────────────────────────────────────────────

  describe "POST /listings with valid params" do
    before { log_in_as(seller) }

    let(:valid_params) do
      {
        product: {
          name: "MacBook Pro 14",
          description: "Excellent condition, barely used, comes with original box.",
          price: "1200.00",
          condition: "Like New"
        }
      }
    end

    it "creates a new Product record" do
      expect do
        post community_listings_path(community_slug: community.slug), params: valid_params
      end.to change(Product, :count).by(1)
    end

    it "redirects to the new product's show page" do
      post community_listings_path(community_slug: community.slug), params: valid_params
      expect(response).to redirect_to(community_product_path(community_slug: community.slug, id: Product.last))
    end

    it "sets seller_id to the current user" do
      post community_listings_path(community_slug: community.slug), params: valid_params
      expect(Product.last.seller_id).to eq(seller.id)
    end

    it "sets sale_status to active" do
      post community_listings_path(community_slug: community.slug), params: valid_params
      expect(Product.last.sale_status).to eq("active")
    end

    it "shows a success flash message after redirect" do
      post community_listings_path(community_slug: community.slug), params: valid_params
      follow_redirect!
      expect(response.body).to include("published").or include("success").or include("created")
    end

    it "sets the product name correctly" do
      post community_listings_path(community_slug: community.slug), params: valid_params
      expect(Product.last.name).to eq("MacBook Pro 14")
    end

    it "sets the condition correctly" do
      post community_listings_path(community_slug: community.slug), params: valid_params
      expect(Product.last.condition).to eq("Like New")
    end
  end

  # ─── Invalid submission ───────────────────────────────────────────────────

  describe "POST /listings with invalid params" do
    before { log_in_as(seller) }

    context "when name is missing" do
      it "does not create a product" do
        expect do
          post community_listings_path(community_slug: community.slug),
               params: { product: { description: "Long enough description here", price: 100 } }
        end.not_to change(Product, :count)
      end

      it "re-renders the form" do
        post community_listings_path(community_slug: community.slug),
             params: { product: { description: "Long enough description here", price: 100 } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("form")
      end

      it "shows an error message" do
        post community_listings_path(community_slug: community.slug),
             params: { product: { description: "Long enough description here", price: 100 } }
        expect(response.body).to include("Name").or include("name")
      end
    end

    context "when description is too short" do
      it "does not create a product" do
        expect do
          post community_listings_path(community_slug: community.slug),
               params: { product: { name: "Test Item", description: "Too short", price: 100 } }
        end.not_to change(Product, :count)
      end

      it "re-renders the form with an error" do
        post community_listings_path(community_slug: community.slug),
             params: { product: { name: "Test Item", description: "Too short", price: 100 } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Description").or include("description")
      end
    end

    context "when price is negative" do
      it "does not create a product" do
        expect do
          post community_listings_path(community_slug: community.slug),
               params: { product: { name: "Test Item", description: "Long enough description here", price: -50 } }
        end.not_to change(Product, :count)
      end

      it "re-renders the form with an error" do
        post community_listings_path(community_slug: community.slug),
             params: { product: { name: "Test Item", description: "Long enough description here", price: -50 } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Price").or include("price")
      end
    end
  end

  # ─── Image upload ─────────────────────────────────────────────────────────

  describe "POST /listings with image attachment" do
    before { log_in_as(seller) }

    it "attaches a valid image to the created product" do
      valid_image = fixture_file_upload(
        Rails.root.join("spec/fixtures/files/test_image.jpg"),
        "image/jpeg"
      )
      post community_listings_path(community_slug: community.slug), params: {
        product: {
          name: "Camera",
          description: "Great condition digital camera.",
          price: 200,
          image: valid_image
        }
      }
      expect(Product.last.image).to be_attached
    end

    it "rejects images larger than 5MB" do
      large_image = fixture_file_upload(
        Rails.root.join("spec/fixtures/files/large_image.jpg"),
        "image/jpeg"
      )
      expect do
        post community_listings_path(community_slug: community.slug), params: {
          product: {
            name: "Camera",
            description: "Great condition digital camera.",
            price: 200,
            image: large_image
          }
        }
      end.not_to change(Product, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects non-image file types" do
      pdf_file = fixture_file_upload(
        Rails.root.join("spec/fixtures/files/test_document.pdf"),
        "application/pdf"
      )
      expect do
        post community_listings_path(community_slug: community.slug), params: {
          product: {
            name: "Camera",
            description: "Great condition digital camera.",
            price: 200,
            image: pdf_file
          }
        }
      end.not_to change(Product, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  # ─── Listings index ───────────────────────────────────────────────────────

  describe "GET /listings" do
    context "when user is logged in" do
      before { log_in_as(seller) }

      it "returns 200 OK" do
        get community_listings_path(community_slug: community.slug)
        expect(response).to have_http_status(:ok)
      end

      it "shows a link to publish a new product" do
        get community_listings_path(community_slug: community.slug)
        expect(response.body).to include("Publish").or include("New")
      end
    end

    context "when visitor is not logged in" do
      it "redirects to the login page" do
        get community_listings_path(community_slug: community.slug)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /listings/:id" do
    let!(:product) do
      Product.create!(
        name: "Mechanical Keyboard",
        description: "Hot-swappable keyboard with linear switches.",
        price: 350,
        seller: seller,
        community: community,
        sale_status: :active
      )
    end

    let(:other_user) do
      User.create!(
        name: "Other User",
        email: TestData.unique_email(prefix: "other"),
        community: community,
        password: "password123",
        password_confirmation: "password123"
      )
    end

    context "when visitor is not logged in" do
      it "redirects to the login page" do
        delete community_listing_path(community_slug: community.slug, id: product.id)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when logged in as the seller" do
      before { log_in_as(seller) }

      it "marks the product as offlined" do
        delete community_listing_path(community_slug: community.slug, id: product.id)
        expect(response).to redirect_to(community_listings_path(community_slug: community.slug))
        expect(product.reload.sale_status).to eq("offlined")
      end
    end

    context "when logged in as another user" do
      before { log_in_as(other_user) }

      it "returns not found and keeps status unchanged" do
        delete community_listing_path(community_slug: community.slug, id: product.id)
        expect(response).to have_http_status(:not_found)
        expect(product.reload.sale_status).to eq("active")
      end
    end
  end
end
