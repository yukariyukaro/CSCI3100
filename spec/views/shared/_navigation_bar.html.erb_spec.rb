require "rails_helper"

# ─────────────────────────────────────────────────────────────────────────────
# Navigation Bar — Theme Toggle Tests (TDD)
#
# Tests verify:
#   - Theme toggle button is rendered in the navbar
#   - Correct Stimulus data attributes (data-controller, data-action)
#   - Both sun and moon icon spans are present
#   - Accessibility: aria-label on the button
#   - Correct CSS classes for animation and positioning
#
# Written BEFORE implementation (red). Will pass after feature is implemented.
# ─────────────────────────────────────────────────────────────────────────────

RSpec.describe "shared/_navigation_bar", type: :view do
  # logged_in? and current_page? are controller helper_methods exposed to views.
  # We define them directly on the view singleton to avoid double-verification errors.
  before do
    without_partial_double_verification do
      allow(view).to receive(:logged_in?).and_return(false)
      allow(view).to receive(:current_page?).and_return(false)
    end
  end

  # ── Theme Toggle Button ──────────────────────────────────────────────────

  describe "theme toggle button" do
    before { render partial: "shared/navigation_bar" }

    it "renders a button with data-controller='theme'" do
      expect(rendered).to include('data-controller="theme"')
    end

    it "renders the correct data-action for toggle" do
      expect(rendered).to include('data-action="click->theme#toggle"')
    end

    it "includes an aria-label for accessibility" do
      expect(rendered).to include('aria-label="Toggle theme"')
    end

    it "renders the sun icon span with class theme-icon-sun" do
      expect(rendered).to include('class="theme-icon-sun')
    end

    it "renders the moon icon span with class theme-icon-moon" do
      expect(rendered).to include('class="theme-icon-moon')
    end

    it "includes the theme-toggle CSS class on the button" do
      expect(rendered).to include("theme-toggle")
    end

    it "sets initial data-dark='false' on the button" do
      expect(rendered).to include('data-dark="false"')
    end
  end

  # ── Layout: button position relative to user avatar ─────────────────────

  describe "layout order" do
    before do
      user = User.create!(
        name: "Alice",
        email: TestData.unique_email(prefix: "nav"),
        password: "password123",
        password_confirmation: "password123"
      )
      without_partial_double_verification do
        allow(view).to receive(:logged_in?).and_return(true)
        allow(view).to receive(:current_user).and_return(user)
        allow(view).to receive(:current_page?).and_return(false)
      end
      render partial: "shared/navigation_bar"
    end

    it "renders theme toggle before the user dropdown" do
      toggle_pos = rendered.index('data-controller="theme"')
      dropdown_pos = rendered.index("dropdown-end")
      expect(toggle_pos).to be < dropdown_pos,
        "Expected theme toggle to appear before the user dropdown in the HTML"
    end
  end
end
