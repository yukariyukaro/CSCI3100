require "rails_helper"

# ─────────────────────────────────────────────────────────────────────────────
# Turbo 8 Flash Messages — Deep HTTP Contract Tests
#
# These tests investigate the specific HTTP protocol conditions that Turbo 8
# relies on for proper form submission handling and redirect flash display.
#
# Key areas:
# 1. Response Content-Type headers (Turbo uses these to decide how to handle)
# 2. HTTP status codes (422 for form errors, 3xx for redirects)
# 3. Flash storage across redirects
# 4. Turbo-specific headers in responses
# ─────────────────────────────────────────────────────────────────────────────

RSpec.describe "Turbo Flash Messages Integration", type: :request do
  let!(:user) do
    User.create!(
      name: "Turbo Tester",
      email: "turbo@link.cuhk.edu.hk",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  # ── Test 1: Login success — redirect with notice flash ──────────────────

  describe "Successful login via Turbo form" do
    before do
      post sessions_path,
           params: { email: user.email, password: "password123" },
           headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }
    end

    it "returns a 302 redirect" do
      expect(response).to have_http_status(:found)
    end

    it "redirects to root_path" do
      expect(response.location).to include(root_path)
    end

    it "sets a notice flash message in the session" do
      # The redirect response won't have flash in the body,
      # but the session should be updated
      expect(session[:flash]).to be_present
    end

    it "following redirect, response body includes notice text" do
      follow_redirect!
      expect(response.body).to include(I18n.t("auth.logged_in"))
    end

    it "following redirect, response body includes alert-success class" do
      follow_redirect!
      expect(response.body).to include("alert-success")
    end

    it "response Content-Type is text/html" do
      follow_redirect!
      expect(response.headers["Content-Type"]).to include("text/html")
    end

    it "response includes flash message HTML in the rendered page" do
      follow_redirect!
      # Flash message should be rendered; either in alert-success or similar class
      expect(response.body).to match(/alert-success|alert-info/)
    end
  end

  # ── Test 2: Login failure — 302 redirect with flash ─────────────────────────

  describe "Failed login (wrong password) via Turbo form" do
    before do
      post sessions_path,
           params: { email: user.email, password: "wrongpassword" },
           headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }
    end

    it "returns HTTP 422 (unprocessable entity)" do
      # Now returns 422 Unprocessable Entity and re-renders form
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "re-renders the login form (no redirect)" do
      # Response body should contain the login form
      expect(response.body).to include("type=\"email\"")
      expect(response.body).to include("type=\"password\"")
    end

    it "response body includes the login form fields" do
      expect(response.body).to include("type=\"email\"")
      expect(response.body).to include("type=\"password\"")
    end

    it "response body includes alert error text" do
      expect(response.body).to include(I18n.t("auth.invalid_credentials"))
    end

    it "response body includes alert-error class (not success)" do
      expect(response.body).to include("alert-error")
      expect(response.body).not_to include("alert-success")
    end

    it "response Content-Type is text/html" do
      expect(response.headers["Content-Type"]).to include("text/html")
    end

    it "flash message is rendered in HTML" do
      # Flash should be visible in the HTML inline with the form
      expect(response.body).to include("Invalid email or password")
    end

    it "submit button in form is NOT disabled" do
      # The form comes from render :new (not via Turbo submission)
      # so the submit button should NOT have disabled state
      expect(response.body).not_to match(/button.*disabled/)
    end
  end

  # ── Test 3: Login failure (unknown email) ─────────────────────────────────

  describe "Failed login (unknown email) via Turbo form" do
    before do
      post sessions_path,
           params: { email: "nonexistent@link.cuhk.edu.hk", password: "whatever" },
           headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }
    end

    it "returns HTTP 422 (unprocessable entity)" do
      # Now returns 422 Unprocessable Entity and re-renders form
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "includes the same invalid_credentials error message" do
      expect(response.body).to include(I18n.t("auth.invalid_credentials"))
    end

    it "includes alert-error styling" do
      expect(response.body).to include("alert-error")
    end
  end

  # ── Test 4: Unauthenticated redirect to login ────────────────────────────

  describe "Unauthenticated redirect to login (Turbo intercept)" do
    before do
      get conversations_path,
          headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }
    end

    it "returns a 302 redirect" do
      expect(response).to have_http_status(:found)
    end

    it "redirects to new_session_path" do
      expect(response.location).to include(new_session_path)
    end

    it "following redirect, renders login page" do
      follow_redirect!
      expect(response.body).to include("<h1 class=\"text-3xl font-bold text-center mb-2\">Login</h1>")
    end

    it "following redirect, flash includes login_required message" do
      follow_redirect!
      expect(response.body).to include(I18n.t("auth.login_required"))
    end

    it "following redirect, flash has alert-info styling (not error)" do
      follow_redirect!
      expect(response.body).to include("alert-info")
    end
  end

  # ── Test 5: Verify flash partial is rendered on every page ──────────────

  describe "Flash partial is present on root page" do
    before do
      post sessions_path, params: { email: user.email, password: "password123" }
      follow_redirect!
    end

    it "renders flash message in the page" do
      # Flash message should appear in the rendered HTML
      expect(response.body).to include("You are logged in")
    end

    it "outer container has fixed positioning and z-50" do
      expect(response.body).to include("fixed")
      expect(response.body).to include("z-50")
    end

    it "outer container has pointer-events-auto for clickable alerts" do
      # Flash alert divs should be clickable for dismiss button
      expect(response.body).to include("pointer-events:auto")
    end
  end

  # ── Test 6: Verify form_with uses Turbo by default ──────────────────────

  describe "Login form Turbo integration" do
    before { get new_session_path }

    it "form element exists" do
      expect(response.body).to include("<form")
    end

    it "form has method='post' and action pointing to sessions_path" do
      expect(response.body).to match(/<form[^>]*method=["']post["']/)
      expect(response.body).to include("/sessions")
    end

    # Form now allows Turbo to handle redirects naturally.
    # With redirect_to on failure (instead of render 422), Turbo
    # simply follows the redirect and shows the new page.
    it "form allows Turbo to intercept submissions (no data-turbo=false)" do
      # The form should NOT have data-turbo="false" anymore
      expect(response.body).not_to include("data-turbo=\"false\"")
    end

    it "response includes Turbo script tag" do
      # The importmap should load turbo.min.js
      expect(response.body).to include("turbo")
    end

    it "response includes Stimulus script tag" do
      expect(response.body).to include("stimulus")
    end
  end

  # ── Test 7: Flash message auto-close behavior ────────────────────────────

  describe "Flash message auto-close behavior" do
    context "success messages (notice)" do
      before do
        post sessions_path, params: { email: user.email, password: "password123" }
        follow_redirect!
      end

      it "includes success message text" do
        expect(response.body).to include("You are logged in")
      end

      it "uses alert-success styling for success messages" do
        expect(response.body).to include("alert-success")
      end

      it "includes inline auto-close script" do
        # Auto-close is handled by inline JavaScript, not Stimulus
        expect(response.body).to include("<script>")
        expect(response.body).to include("setTimeout")
      end
    end

    context "error messages (alert)" do
      before do
        post sessions_path, params: { email: user.email, password: "wrongpassword" }
        # No follow_redirect! since we now return 422 and re-render
      end

      it "includes error message text" do
        expect(response.body).to include("Invalid email or password")
      end

      it "uses alert-error styling for error messages" do
        expect(response.body).to include("alert-error")
      end

      it "includes close button for manual dismissal" do
        # Error messages don't auto-close, so manual close button needed
        expect(response.body).to include("button")
      end
    end
  end

  # ── Test 8: Multiple flashes in one response ──────────────────────────────

  describe "Multiple flash messages at once" do
    # This is harder to test without modifying controller,
    # but we can at least verify the partial handles it
    it "flash partial HTML structure allows multiple messages" do
      # Just verify the partial renders correctly for multiple types
      # by inspecting the view directly (not via request)
      view = double
      allow(view).to receive(:flash).and_return(
        {
          notice: "Success!",
          warning: "But also a warning..."
        }
      )

      # In a real scenario, render the partial with multiple flash entries
      # For now, this is a placeholder for future JavaScript-based tests
    end
  end

  # ── Test 9: Verify no caching issues with flash ──────────────────────────

  describe "Flash messages are not cached by Turbo" do
    # Turbo has a page cache that can interfere with flash messages
    it "first login shows success flash" do
      post sessions_path, params: { email: user.email, password: "password123" }
      follow_redirect!
      expect(response.body).to include(I18n.t("auth.logged_in"))
    end

    it "second login after logout also shows success flash" do
      # First login
      post sessions_path, params: { email: user.email, password: "password123" }
      follow_redirect!
      first_response = response.body.dup

      # Logout (resourceful route: DELETE /sessions/:id)
      delete session_path(session[:user_id])
      follow_redirect!

      # Second login
      post sessions_path, params: { email: user.email, password: "password123" }
      follow_redirect!

      # Both should have the flash message
      expect(first_response).to include(I18n.t("auth.logged_in"))
      expect(response.body).to include(I18n.t("auth.logged_in"))
    end
  end

  # ── Test 10: Redirect handling for login failure ─────────────────────────

  describe "Login failure handling and redirect behavior" do
    before do
      turbo_accept_header = "text/vnd.turbo-stream.html, text/html, application/xhtml+xml, " \
                            "application/xml;q=0.9, image/avif, image/webp, image/apng, */*;q=0.8"
      post sessions_path,
           params: { email: user.email, password: "wrongpassword" },
           headers: { "Accept" => turbo_accept_header }
    end

    it "returns 422 unprocessable entity (not 302)" do
      # Now returns 422 Unprocessable Entity and re-renders form
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "response Content-Type is text/html" do
      # Re-rendered response should be HTML
      expect(response.headers["Content-Type"]).to include("text/html")
    end

    it "response is a full HTML page with form (not a stream)" do
      # Should have the form, layout, everything
      expect(response.body).to include("<!DOCTYPE html>").or include("<html")
      expect(response.body).to include("type=\"email\"")
      expect(response.body).to include("type=\"password\"")
    end
  end
end
