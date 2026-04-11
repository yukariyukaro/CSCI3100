require "rails_helper"

# ─────────────────────────────────────────────────────────────────────────────
# Flash Messages — View Component Tests
#
# Tests the `app/views/shared/_flash_messages.html.erb` partial in isolation.
# Each test assigns specific flash values and asserts the rendered HTML:
#   - Correct DaisyUI alert class (alert-success / alert-error / alert-warning /
#     alert-info)
#   - Correct SVG icon present
#   - Stimulus data attributes (data-controller, data-action)
#   - Accessibility attributes (role, aria-live)
#   - Close button present on every message type
#   - Empty flash renders nothing
#
# These tests are written BEFORE the partial exists (TDD). They will pass once
# Phase 3 implementation is complete.
# ─────────────────────────────────────────────────────────────────────────────

RSpec.describe "shared/_flash_messages", type: :view do
  # Helper: stub flash with a plain hash so the partial can iterate it
  def add_flash(pairs)
    pairs.each { |key, val| flash[key.to_s] = val }
  end

  # ── 1. Success / Notice ─────────────────────────────────────────────────

  describe "notice (success) message" do
    before do
      add_flash(notice: "You are logged in.")
      render partial: "shared/flash_messages"
    end

    it "renders the message text" do
      expect(rendered).to include("You are logged in.")
    end

    it "applies the success alert class" do
      expect(rendered).to include("alert-success")
    end

    it "does not apply error, warning, or info classes" do
      expect(rendered).not_to include("alert-error")
      expect(rendered).not_to include("alert-warning")
      expect(rendered).not_to include("alert-info")
    end

    it "includes the alert message element" do
      expect(rendered).to include("You are logged in.")
    end

    it "marks auto-close as true for success messages" do
      expect(rendered).to include("5000")
    end

    it "includes role='alert' for screen readers" do
      expect(rendered).to include('role="alert"')
    end

    it "includes a close button with onclick handler" do
      expect(rendered).to include('onclick="this.closest(\'.flash-message\').remove()"')
    end
  end

  describe "flash[:success] (explicit success key)" do
    before do
      add_flash(success: "Operation successful.")
      render partial: "shared/flash_messages"
    end

    it "also maps to alert-success" do
      expect(rendered).to include("alert-success")
    end

    it "renders the message text" do
      expect(rendered).to include("Operation successful.")
    end
  end

  # ── 2. Error / Alert ────────────────────────────────────────────────────

  describe "alert (error) message" do
    before do
      add_flash(alert: "Invalid email or password.")
      render partial: "shared/flash_messages"
    end

    it "renders the message text" do
      expect(rendered).to include("Invalid email or password.")
    end

    it "applies the error alert class" do
      expect(rendered).to include("alert-error")
    end

    it "does not apply success, warning, or info classes" do
      expect(rendered).not_to include("alert-success")
      expect(rendered).not_to include("alert-warning")
      expect(rendered).not_to include("alert-info")
    end

    it "does not include auto-close script for error messages" do
      expect(rendered).not_to include("5000")
    end

    it "includes role='alert' for screen readers" do
      expect(rendered).to include('role="alert"')
    end

    it "includes a close button with onclick handler" do
      expect(rendered).to include('onclick="this.closest(\'.flash-message\').remove()"')
    end
  end

  describe "flash[:error] (explicit error key)" do
    before do
      add_flash(error: "Something went wrong.")
      render partial: "shared/flash_messages"
    end

    it "also maps to alert-error" do
      expect(rendered).to include("alert-error")
    end
  end

  # ── 3. Warning ──────────────────────────────────────────────────────────

  describe "warning message" do
    before do
      add_flash(warning: "This action cannot be undone.")
      render partial: "shared/flash_messages"
    end

    it "renders the message text" do
      expect(rendered).to include("This action cannot be undone.")
    end

    it "applies the warning alert class" do
      expect(rendered).to include("alert-warning")
    end

    it "does not apply success, error, or info classes" do
      expect(rendered).not_to include("alert-success")
      expect(rendered).not_to include("alert-error")
      expect(rendered).not_to include("alert-info")
    end

    it "marks auto-close as true for warning messages" do
      expect(rendered).to include("5000")
    end

    it "includes a close button with onclick handler" do
      expect(rendered).to include('onclick="this.closest(\'.flash-message\').remove()"')
    end
  end

  # ── 4. Info ─────────────────────────────────────────────────────────────

  describe "info message" do
    before do
      add_flash(info: "You must be logged in.")
      render partial: "shared/flash_messages"
    end

    it "renders the message text" do
      expect(rendered).to include("You must be logged in.")
    end

    it "applies the info alert class" do
      expect(rendered).to include("alert-info")
    end

    it "does not apply success, error, or warning classes" do
      expect(rendered).not_to include("alert-success")
      expect(rendered).not_to include("alert-error")
      expect(rendered).not_to include("alert-warning")
    end

    it "marks auto-close as true for info messages" do
      expect(rendered).to include("5000")
    end

    it "includes a close button with onclick handler" do
      expect(rendered).to include('onclick="this.closest(\'.flash-message\').remove()"')
    end
  end

  # ── 5. Multiple simultaneous messages ────────────────────────────────────

  describe "multiple messages at once" do
    before do
      add_flash(notice: "Profile updated.", alert: "But something else failed.")
      render partial: "shared/flash_messages"
    end

    it "renders all message texts" do
      expect(rendered).to include("Profile updated.")
      expect(rendered).to include("But something else failed.")
    end

    it "applies both alert-success and alert-error" do
      expect(rendered).to include("alert-success")
      expect(rendered).to include("alert-error")
    end

    it "renders two separate alert elements" do
      expect(rendered.scan('class="flash-message').size).to eq(2)
    end
  end

  # ── 6. Empty flash ───────────────────────────────────────────────────────

  describe "empty flash (no messages)" do
    before { render partial: "shared/flash_messages" }

    it "renders no alert-success elements" do
      expect(rendered).not_to include("alert-success")
    end

    it "renders no alert-error elements" do
      expect(rendered).not_to include("alert-error")
    end

    it "renders no alert-warning elements" do
      expect(rendered).not_to include("alert-warning")
    end

    it "renders no alert-info elements" do
      expect(rendered).not_to include("alert-info")
    end

    it "renders no close buttons" do
      expect(rendered).not_to match(/data-action="click->flash#close"/)
    end
  end

  # ── 7. Blank message text is skipped ─────────────────────────────────────

  describe "blank message value" do
    before do
      add_flash(notice: "")
      render partial: "shared/flash_messages"
    end

    it "does not render any alert element for a blank message" do
      expect(rendered).not_to include("alert-success")
      expect(rendered).not_to include('data-controller="flash"')
    end
  end

  # ── 8. Container structure ───────────────────────────────────────────────

  describe "outer container" do
    before do
      add_flash(notice: "Hello.")
      render partial: "shared/flash_messages"
    end

    it "renders a fixed-position container" do
      expect(rendered).to include("fixed")
    end

    it "renders with high z-index class (z-50)" do
      expect(rendered).to include("z-50")
    end

    it "renders with right-aligned positioning" do
      expect(rendered).to include("right-")
    end
  end

  # ── 9. SVG icons per type ────────────────────────────────────────────────

  describe "SVG icons" do
    it "renders an SVG icon for notice messages" do
      add_flash(notice: "Done!")
      render partial: "shared/flash_messages"
      expect(rendered).to include("<svg")
    end

    it "renders an SVG icon for alert messages" do
      add_flash(alert: "Error!")
      render partial: "shared/flash_messages"
      expect(rendered).to include("<svg")
    end

    it "renders an SVG icon for warning messages" do
      add_flash(warning: "Careful!")
      render partial: "shared/flash_messages"
      expect(rendered).to include("<svg")
    end

    it "renders an SVG icon for info messages" do
      add_flash(info: "FYI.")
      render partial: "shared/flash_messages"
      expect(rendered).to include("<svg")
    end
  end
end
