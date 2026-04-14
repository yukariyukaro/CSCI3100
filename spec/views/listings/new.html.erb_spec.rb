require "rails_helper"

# ─────────────────────────────────────────────────────────────────────────────
# Listings New — Dark-mode semantic colour tests (TDD)
#
# The form MUST use DaisyUI semantic tokens (base-100, base-content…) instead
# of hard-coded Tailwind grey classes so it adapts to both light and dark themes.
#
# Red criteria (will FAIL before fix):
#   - No bg-white in the form card
#   - No text-gray-* colour classes in labels / headings
#   - Page heading uses text-base-content
#   - Labels use text-base-content
#   - Helper text uses text-base-content/... opacity variant
# ─────────────────────────────────────────────────────────────────────────────

RSpec.describe "listings/new.html.erb", type: :view do
  let(:seller) do
    User.create!(
      name: "Seller",
      email: TestData.unique_email(prefix: "listing_view"),
      community: default_community,
      password: "password123",
      password_confirmation: "password123"
    )
  end

  before do
    assign(:product, Product.new)
    view.singleton_class.send(:define_method, :current_user) { seller }
    view.singleton_class.send(:define_method, :logged_in?) { true }
    Current.community = seller.community
    render
  end

  # ── Form card background ──────────────────────────────────────────────────

  it "does not use hardcoded bg-white on the form card" do
    expect(rendered).not_to match(/class="[^"]*bg-white[^"]*"/)
  end

  it "uses bg-base-100 (or bg-base-200) on the form card for theme compatibility" do
    expect(rendered).to match(/bg-base-\d00/)
  end

  # ── Page heading colours ─────────────────────────────────────────────────

  it "does not use hardcoded text-gray-900 for the page heading" do
    expect(rendered).not_to include("text-gray-900")
  end

  it "does not use hardcoded text-gray-500 for the page subtitle" do
    expect(rendered).not_to include("text-gray-500")
  end

  # ── Label colours ────────────────────────────────────────────────────────

  it "does not use hardcoded text-gray-700 for labels" do
    expect(rendered).not_to include("text-gray-700")
  end

  it "does not use hardcoded text-gray-400 for optional / helper text" do
    expect(rendered).not_to include("text-gray-400")
  end

  # ── Uses semantic DaisyUI tokens ─────────────────────────────────────────

  it "uses text-base-content for the page heading" do
    expect(rendered).to include("text-base-content")
  end
end
