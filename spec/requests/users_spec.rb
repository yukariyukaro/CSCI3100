# filepath: spec/requests/users_spec.rb
require "rails_helper"

RSpec.describe "Users", type: :request do
  let(:user_email) { TestData.unique_email(prefix: "alice") }
  let(:other_user_email) { TestData.unique_email(prefix: "bob") }

  let(:user) do
    User.create!(
      name: "Alice",
      email: user_email,
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let(:other_user) do
    User.create!(
      name: "Bob",
      email: other_user_email,
      password: "password123",
      password_confirmation: "password123"
    )
  end

  # ─── GET /users/:id ──────────────────────────────────────────────────────────

  describe "GET /users/:id" do
    it "returns 200 OK for a valid user" do
      get user_path(user)
      expect(response).to have_http_status(:ok)
    end

    it "displays the user's name" do
      get user_path(user)
      expect(response.body).to include("Alice")
    end

    it "displays the user's avatar placeholder when no avatar is attached" do
      get user_path(user)
      expect(response.body).to include("avatar").or include("img")
    end

    it "returns 404 for a non-existent user" do
      get user_path(id: 999_999)
      expect(response).to have_http_status(:not_found)
    end

    context "with products belonging to the user" do
      before do
        Product.create!(name: "Sold iPhone", description: "Great phone", seller: user, price: 100, sale_status: :active)
        Product.create!(name: "Old MacBook", description: "Good laptop", seller: user, price: 200, sale_status: :sold)
        Product.create!(name: "Hidden Listing", description: "Removed from market visibility", seller: user, price: 50,
                        sale_status: :unlisted)
      end

      it "displays the user's active products" do
        get user_path(user)
        expect(response.body).to include("Sold iPhone")
        expect(response.body).not_to include("Hidden Listing")
      end

      it "shows the products tab section" do
        get user_path(user)
        expect(response.body).to include("My Items").or include("Items")
      end
    end

    context "transaction history visibility" do
      let(:product) do
        Product.create!(name: "Laptop", description: "Good condition, barely used.", seller: user, price: 300)
      end

      before do
        Transaction.create!(
          product: product, buyer: other_user, seller: user, status: :completed
        )
      end

      it "hides transaction history for unauthenticated visitors" do
        get user_path(user)
        expect(response.body).not_to include("completed")
        expect(response.body).to include("Log in").or include("log in").or include("login")
      end

      it "shows transaction history when the owner is logged in" do
        post sessions_path, params: { email: user.email, password: "password123" }
        get user_path(user)
        expect(response.body).to include("Transaction").or include("History")
      end

      it "hides transaction history when a different user is logged in" do
        post sessions_path, params: { email: other_user.email, password: "password123" }
        get user_path(user)
        expect(response.body).not_to include("completed")
        expect(response.body).to include("Log in").or include("log in").or include("login")
      end
    end
  end

  # ─── PATCH /users/:id (avatar upload) ───────────────────────────────────────

  describe "PATCH /users/:id" do
    context "when not logged in" do
      it "redirects to login page" do
        patch user_path(user), params: { user: { name: "New Name" } }
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when logged in as a different user" do
      it "returns forbidden or redirects away" do
        post sessions_path, params: { email: other_user.email, password: "password123" }
        patch user_path(user), params: { user: { name: "Hacked Name" } }
        expect(response.status).to be_in([302, 403])
      end
    end

    context "when logged in as the owner" do
      before { post sessions_path, params: { email: user.email, password: "password123" } }

      it "updates the user's name successfully" do
        patch user_path(user), params: { user: { name: "Updated Alice" } }
        expect(response).to redirect_to(user_path(user))
        expect(user.reload.name).to eq("Updated Alice")
      end

      it "uploads a valid avatar and redirects" do
        avatar = fixture_file_upload(
          Rails.root.join("spec/fixtures/files/avatar.jpg"),
          "image/jpeg"
        )
        patch user_path(user), params: { user: { avatar: avatar } }
        expect(response).to redirect_to(user_path(user))
        expect(user.reload.avatar).to be_attached
      end

      it "rejects an avatar with invalid content type" do
        bad_file = fixture_file_upload(
          Rails.root.join("spec/fixtures/files/not_an_image.txt"),
          "text/plain"
        )
        patch user_path(user), params: { user: { avatar: bad_file } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("avatar").or include("Avatar")
      end
    end
  end
end
