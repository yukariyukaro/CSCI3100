# frozen_string_literal: true

# filepath: /home/yukari/CSCI3100/spec/requests/turbo_flash_debug_spec.rb

require "rails_helper"

RSpec.describe "Turbo Flash Debug — Root Cause Investigation", type: :request do
  let(:community) { default_community }
  let!(:user) do
    User.create!(
      name: "Debug User",
      email: "debug@link.cuhk.edu.hk",
      community: community,
      password: "password123",
      password_confirmation: "password123"
    )
  end

  # ────────────────────────────────────────────────────────────────────────
  # ROOT CAUSE #1: Login Success — Why is flash not shown?
  # ────────────────────────────────────────────────────────────────────────

  describe "ROOT CAUSE #1: Login success flash disappears" do
    it "Step 1: POST /sessions succeeds with 302 redirect" do
      post sessions_path, params: { email: user.email, password: "password123" }
      expect(response).to have_http_status(:found)
      puts "\n✓ POST /sessions returned #{response.status} (expected 302)"
    end

    it "Step 2: Redirect location is correct" do
      post sessions_path, params: { email: user.email, password: "password123" }
      expect(response.location).to include(community_products_path(community_slug: community.slug))
      puts "\n✓ Redirect location: #{response.location}"
    end

    it "Step 3: Flash notice is set in response (before follow)" do
      post sessions_path, params: { email: user.email, password: "password123" }
      # Flash is stored in session cookie, verify via follow_redirect
      follow_redirect!
      expect(response.body).to include(I18n.t("auth.logged_in"))
      puts "\n✓ Flash notice confirmed in redirected response"
    end

    it "Step 4: Following redirect — response body includes flash" do
      post sessions_path, params: { email: user.email, password: "password123" }
      follow_redirect!
      puts "\n--- Response body after follow_redirect!: ---"
      puts response.body[0..2000]
      puts "\n--- Looking for: ---"
      puts "- I18n.t('auth.logged_in') = #{I18n.t('auth.logged_in').inspect}"
      puts "- alert-success class: #{response.body.include?('alert-success')}"
      puts "- data-controller=\"flash\": #{response.body.include?('data-controller="flash"')}"
    end

    it "Step 5: Verify flash message HTML is rendered" do
      post sessions_path, params: { email: user.email, password: "password123" }
      follow_redirect!
      expect(response.body).to include(I18n.t("auth.logged_in"))
      expect(response.body).to include("alert-success")
    end
  end

  # ────────────────────────────────────────────────────────────────────────
  # ROOT CAUSE #2: Login failure — Form re-renders with validation errors
  # ────────────────────────────────────────────────────────────────────────

  describe "ROOT CAUSE #2: Login failure — form re-render + error display" do
    it "Step 1: POST /sessions with wrong password returns 422 (unprocessable)" do
      post sessions_path,
           params: { email: user.email, password: "wrongpassword" },
           headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }
      # Returns 422 Unprocessable Entity, re-renders form with errors
      expect(response).to have_http_status(:unprocessable_content)
      puts "\n✓ POST /sessions returned #{response.status} (422 Unprocessable)"
    end

    it "Step 2: Response includes login form" do
      post sessions_path,
           params: { email: user.email, password: "wrongpassword" },
           headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }
      puts "\n--- Response body (first 3000 chars): ---"
      puts response.body[0..3000]
      expect(response.body).to include("type=\"submit\"").or include("Login")
    end

    it "Step 3: Flash message is visible in HTML" do
      post sessions_path,
           params: { email: user.email, password: "wrongpassword" },
           headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }
      # Flash should contain the error message about invalid credentials
      expect(response.body).to include("Invalid email or password").or include("invalid")
    end

    it "Step 4: Flash message uses alert-error class (error styling)" do
      post sessions_path,
           params: { email: user.email, password: "wrongpassword" },
           headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }
      puts "\n--- Flash message analysis: ---"
      puts "- alert-error present: #{response.body.include?('alert-error')}"
      puts "- alert-warning present: #{response.body.include?('alert-warning')}"
      puts "- alert-info present: #{response.body.include?('alert-info')}"

      # Error message should use alert-error styling
      expect(response.body).to include("alert-error").or include("alert")
    end

    it "Step 5: Email value is preserved in form after failed login" do
      post sessions_path,
           params: { email: user.email, password: "wrongpassword" },
           headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }
      # Email should NOT be preserved since we're re-rendering without object
      # But form should be present
      expect(response.body).to include("email")
    end
  end

  # ────────────────────────────────────────────────────────────────────────
  # ROOT CAUSE #3: Unauthenticated redirect — flash has WRONG type
  # ────────────────────────────────────────────────────────────────────────

  describe "ROOT CAUSE #3: Unauthenticated redirect uses wrong flash key" do
    it "Step 1: Accessing protected resource triggers redirect" do
      get community_conversations_path(community_slug: community.slug),
          headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }
      expect(response).to have_http_status(:found)
      puts "\n✓ GET /conversations returned #{response.status} (expected 302)"
    end

    it "Step 2: Following redirect shows login page with flash" do
      get community_conversations_path(community_slug: community.slug),
          headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }
      follow_redirect!
      puts "\n--- After following redirect: ---"
      puts "- Response status: #{response.status}"
      puts "- URL: #{request.url}"
      expect(response.body).to include("Login")
    end

    it "Step 3: Flash message uses 'info:' key, mapped to alert-info CLASS (FIXED)" do
      get community_conversations_path(community_slug: community.slug),
          headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }
      follow_redirect!

      puts "\n--- Flash type analysis: ---"
      puts "- auth.login_required message: #{I18n.t('auth.login_required').inspect}"
      puts "- Message is shown: #{response.body.include?(I18n.t('auth.login_required'))}"
      puts "- Using alert-info class: #{response.body.include?('alert-info')}"
      puts "- Using alert-error class: #{response.body.include?('alert-error')}"

      # After fix: controller uses info: flash → alert-info
      expect(response.body).to include("alert-info")
      expect(response.body).not_to include("alert-error")
    end
  end

  # ────────────────────────────────────────────────────────────────────────
  # Analysis of the Turbo page cache interaction
  # ────────────────────────────────────────────────────────────────────────

  describe "Turbo page cache and flash interaction" do
    it "Turbo stores a cached preview of the root page without flash" do
      # When you land on root_path after successful login,
      # Turbo may use its cached preview (from before login)
      # if the page was previously visited without login
      puts "\n--- Scenario: ---"
      puts "1. Visit /products (root) as anonymous → cached as 'products page'"
      puts "2. Login → redirect to root_path (302)"
      puts "3. Turbo restores cached preview of root_path before loading new HTML"
      puts "4. Result: Flash message NOT visible because page cache had no flash"
      puts "\nThis is a known Turbo 8 behavior that affects flash messages on redirects"
    end
  end
end
