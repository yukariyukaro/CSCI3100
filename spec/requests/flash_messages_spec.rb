require "rails_helper"

# ─────────────────────────────────────────────────────────────────────────────
# Flash Messages — Integration Tests
#
# Covers every controller action that sets a flash message so we can confirm:
#   1. The correct flash key/text is set by the controller.
#   2. After following the redirect, the rendered page contains the message
#      text inside the flash component (alert-* CSS class).
#   3. flash.now messages (rendered inline, no redirect) are also visible.
#
# Relies only on the existing i18n keys in config/locales/en.yml.
# These tests are written BEFORE the `_flash_messages` component exists (TDD).
# They will pass once Phase 3 implementation is complete.
# ─────────────────────────────────────────────────────────────────────────────

RSpec.describe "Flash Messages", type: :request do
  # ── Shared fixtures ──────────────────────────────────────────────────────

  let!(:user) do
    User.create!(
      name: "Flash Tester",
      email: "flash@link.cuhk.edu.hk",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:seller) do
    User.create!(
      name: "Seller User",
      email: "seller_flash@link.cuhk.edu.hk",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:product) do
    Product.create!(
      name: "Test Phone",
      description: "A phone for testing flash messages",
      seller: seller
    )
  end

  # Helper: POST to sessions and simulate login
  def log_in_as(user)
    post sessions_path, params: { email: user.email, password: "password123" }
  end

  # ── 1. Authentication flash messages ─────────────────────────────────────

  describe "Authentication — SessionsController" do
    context "successful login" do
      it "redirects to root after login" do
        post sessions_path, params: { email: user.email, password: "password123" }
        expect(response).to redirect_to(root_path)
      end

      it "sets a notice flash with the logged-in message" do
        post sessions_path, params: { email: user.email, password: "password123" }
        expect(flash[:notice]).to eq(I18n.t("auth.logged_in"))
      end

      it "renders the success flash message text on the next page" do
        post sessions_path, params: { email: user.email, password: "password123" }
        follow_redirect!
        expect(response.body).to include(I18n.t("auth.logged_in"))
      end

      it "renders the flash inside a success-styled alert element" do
        post sessions_path, params: { email: user.email, password: "password123" }
        follow_redirect!
        expect(response.body).to include("alert-success")
      end
    end

    context "failed login — wrong password" do
      before do
        post sessions_path, params: { email: user.email, password: "wrongpassword" }
      end

      it "re-renders the login page with 422" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "sets flash.now[:alert] with the invalid-credentials message" do
        expect(flash[:alert]).to eq(I18n.t("auth.invalid_credentials"))
      end

      it "renders the error message text inline (no redirect)" do
        expect(response.body).to include(I18n.t("auth.invalid_credentials"))
      end

      it "renders the flash inside an error-styled alert element" do
        expect(response.body).to include("alert-error")
      end
    end

    context "failed login — unknown email" do
      it "also returns invalid-credentials message for unknown email" do
        post sessions_path, params: { email: "nobody@example.com", password: "whatever" }
        expect(response.body).to include(I18n.t("auth.invalid_credentials"))
      end
    end

    context "logout" do
      before do
        log_in_as(user)
        delete session_path(user)
      end

      it "redirects to root after logout" do
        expect(response).to redirect_to(root_path)
      end

      it "sets a notice flash with the logged-out message" do
        expect(flash[:notice]).to eq(I18n.t("auth.logged_out"))
      end

      it "renders the logout message text on the next page" do
        follow_redirect!
        expect(response.body).to include(I18n.t("auth.logged_out"))
      end

      it "renders the flash inside a success-styled alert element" do
        follow_redirect!
        expect(response.body).to include("alert-success")
      end
    end
  end

  # ── 2. authenticate_user! — login-required redirect ──────────────────────

  describe "Authentication gate — ApplicationController#authenticate_user!" do
    # Any action protected by before_action :authenticate_user!
    # We use /conversations (ConversationsController) as a representative target.
    context "unauthenticated user accesses a protected page" do
      before { get conversations_path }

      it "redirects to the login page" do
        expect(response).to redirect_to(new_session_path)
      end

      it "sets an info flash with the login-required message" do
        expect(flash[:info]).to eq(I18n.t("auth.login_required"))
      end

      it "renders the login-required message on the login page" do
        follow_redirect!
        expect(response.body).to include(I18n.t("auth.login_required"))
      end

      it "renders the flash inside an info-styled alert element" do
        follow_redirect!
        expect(response.body).to include("alert-info")
      end
    end

    # /conversations is also protected — /listings/new has no auth gate
    it "shows login-required flash when accessing /conversations unauthenticated" do
      get conversations_path
      follow_redirect!
      expect(response.body).to include(I18n.t("auth.login_required"))
    end
  end

  # ── 3. User registration ──────────────────────────────────────────────────

  describe "User registration — UsersController#create" do
    context "successful registration" do
      let(:new_user_params) do
        {
          user: {
            name: "New Tester",
            email: "newtester@link.cuhk.edu.hk",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end

      it "redirects to root after registration" do
        post users_path, params: new_user_params
        expect(response).to redirect_to(root_path)
      end

      it "sets a notice flash with the logged-in message (auto-login after sign-up)" do
        post users_path, params: new_user_params
        expect(flash[:notice]).to eq(I18n.t("auth.logged_in"))
      end

      it "renders the success message on the next page" do
        post users_path, params: new_user_params
        follow_redirect!
        expect(response.body).to include(I18n.t("auth.logged_in"))
      end

      it "renders the flash inside a success-styled alert element" do
        post users_path, params: new_user_params
        follow_redirect!
        expect(response.body).to include("alert-success")
      end
    end

    context "failed registration — duplicate email" do
      it "re-renders the form with 422 (no flash redirect)" do
        post users_path, params: {
          user: {
            name: "Duplicate",
            email: user.email, # already taken
            password: "password123",
            password_confirmation: "password123"
          }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  # ── 4. User profile update ────────────────────────────────────────────────

  describe "User profile update — UsersController#update" do
    before { log_in_as(user) }

    context "successful update" do
      it "redirects to the user's profile page" do
        patch user_path(user), params: { user: { name: "Updated Name" } }
        expect(response).to redirect_to(user_path(user))
      end

      it "sets a notice flash with the profile-updated message" do
        patch user_path(user), params: { user: { name: "Updated Name" } }
        expect(flash[:notice]).to eq(I18n.t("users.profile.updated"))
      end

      it "renders the profile-updated message on the profile page" do
        patch user_path(user), params: { user: { name: "Updated Name" } }
        follow_redirect!
        expect(response.body).to include(I18n.t("users.profile.updated"))
      end

      it "renders the flash inside a success-styled alert element" do
        patch user_path(user), params: { user: { name: "Updated Name" } }
        follow_redirect!
        expect(response.body).to include("alert-success")
      end
    end
  end

  # ── 5. Transactions flash messages ───────────────────────────────────────

  describe "Transactions — TransactionsController" do
    before { log_in_as(user) }

    context "successful reservation" do
      it "sets a notice flash after reserving a product" do
        post reserve_product_path(product)
        expect(flash[:notice]).to eq(I18n.t("transactions.reserve_success"))
      end

      it "renders the reserve-success message on the product page" do
        post reserve_product_path(product)
        follow_redirect!
        expect(response.body).to include(I18n.t("transactions.reserve_success"))
      end

      it "renders the flash inside a success-styled alert element" do
        post reserve_product_path(product)
        follow_redirect!
        expect(response.body).to include("alert-success")
      end
    end

    context "failed reservation — product not available" do
      before do
        # Reserve first so the product is no longer available
        other_buyer = User.create!(
          name: "Other Buyer",
          email: "other_buyer_flash@example.com",
          password: "password123",
          password_confirmation: "password123"
        )
        product.reserve_by(other_buyer)
      end

      it "sets an alert flash when reservation fails" do
        post reserve_product_path(product)
        expect(flash[:alert]).to eq(I18n.t("transactions.reserve_failed"))
      end

      it "renders the reserve-failed message on the product page" do
        post reserve_product_path(product)
        follow_redirect!
        expect(response.body).to include(I18n.t("transactions.reserve_failed"))
      end

      it "renders the flash inside an error-styled alert element" do
        post reserve_product_path(product)
        follow_redirect!
        expect(response.body).to include("alert-error")
      end
    end

    context "cancel reservation" do
      before { product.reserve_by(user) }

      it "sets a notice flash after cancelling a reservation" do
        delete cancel_reservation_product_path(product)
        expect(flash[:notice]).to eq(I18n.t("transactions.cancel_success"))
      end

      it "renders the cancel-success message on the product page" do
        delete cancel_reservation_product_path(product)
        follow_redirect!
        expect(response.body).to include(I18n.t("transactions.cancel_success"))
      end
    end

    context "mark product as sold" do
      before do
        # seller marks their own product sold
        log_in_as(seller)
        product.reserve_by(user) # must be reserved first
      end

      it "sets a notice flash after marking as sold" do
        patch mark_sold_product_path(product)
        expect(flash[:notice]).to eq(I18n.t("transactions.sold_success"))
      end

      it "renders the sold-success message on the product page" do
        patch mark_sold_product_path(product)
        follow_redirect!
        expect(response.body).to include(I18n.t("transactions.sold_success"))
      end
    end
  end

  # ── 6. Conversations — product not found ─────────────────────────────────

  describe "Conversations — ConversationsController#create" do
    before { log_in_as(user) }

    it "sets an alert flash when product_id is invalid" do
      post conversations_path, params: { conversation: { product_id: 0 } }
      expect(flash[:alert]).to eq(I18n.t("conversations.product_not_found"))
    end

    it "redirects to products_path when product not found" do
      post conversations_path, params: { conversation: { product_id: 0 } }
      expect(response).to redirect_to(products_path)
    end

    it "renders the product-not-found message after redirect" do
      post conversations_path, params: { conversation: { product_id: 0 } }
      follow_redirect!
      expect(response.body).to include(I18n.t("conversations.product_not_found"))
    end

    it "renders the flash inside an error-styled alert element" do
      post conversations_path, params: { conversation: { product_id: 0 } }
      follow_redirect!
      expect(response.body).to include("alert-error")
    end
  end

  # ── 7. Flash message markup structure ────────────────────────────────────

  describe "Flash message HTML structure" do
    context "when a notice flash is present" do
      before do
        log_in_as(user)
        follow_redirect! # land on root_path with flash rendered
      end

      it "wraps the message in a div with class flash-message" do
        expect(response.body).to include('class="flash-message')
      end

      it "includes a close button for user interaction" do
        expect(response.body).to include('aria-label="Close"')
      end

      it "includes role='alert' for accessibility" do
        expect(response.body).to include('role="alert"')
      end
    end

    context "when an alert flash is present" do
      before do
        # Trigger login_required redirect, then follow to login page
        get conversations_path
        follow_redirect!
      end

      it "wraps the error message in a div with class flash-message" do
        expect(response.body).to include('class="flash-message')
      end

      it "includes role='alert' for accessibility" do
        expect(response.body).to include('role="alert"')
      end
    end
  end

  # ── 8. No flash rendered when flash is empty ─────────────────────────────

  describe "No flash messages" do
    it "renders no flash alert elements when visiting root with no flash" do
      get root_path
      # The outer container may still render, but no individual alert divs
      expect(response.body).not_to include("alert-success")
      expect(response.body).not_to include("alert-error")
      expect(response.body).not_to include("alert-warning")
      expect(response.body).not_to include("alert-info")
    end
  end
end
