require "rails_helper"

# ─────────────────────────────────────────────────────────────────────────────
# Theme Toggle — Button Visibility Tests (TDD)
#
# The button uses DaisyUI `btn btn-ghost btn-circle` for a clean icon-only look.
# Key assertions:
#   - Button uses btn-ghost (no heavy border) and btn-circle (round)
#   - Button uses text-base-content so icon auto-adapts in both light/dark
#   - Both sun and moon icon spans are present
#   - Button has type="button" and aria-label
# ─────────────────────────────────────────────────────────────────────────────

RSpec.describe "shared/_navigation_bar theme-toggle visibility", type: :view do
  before do
    view.singleton_class.send(:define_method, :logged_in?) { false }
    view.singleton_class.send(:define_method, :current_page?) { |_| false }
    view.singleton_class.send(:define_method, :current_community_or_default) { nil }
    render partial: "shared/navigation_bar"
  end

  it "uses btn-ghost so there is no heavy border in either theme" do
    button_block = rendered[%r{<button[\s\S]*?data-controller="theme"[\s\S]*?</button>}]
    expect(button_block).to be_present, "Could not find theme toggle button"
    expect(button_block).to include("btn-ghost"),
                            "Button must use btn-ghost for a borderless icon appearance"
  end

  it "uses btn-circle for a round icon button" do
    button_block = rendered[%r{<button[\s\S]*?data-controller="theme"[\s\S]*?</button>}]
    expect(button_block).to be_present, "Could not find theme toggle button"
    expect(button_block).to include("btn-circle"),
                            "Button must use btn-circle for round shape"
  end

  it "uses text-base-content so icon is visible in both light and dark mode" do
    button_block = rendered[%r{<button[\s\S]*?data-controller="theme"[\s\S]*?</button>}]
    expect(button_block).to be_present, "Could not find theme toggle button"
    expect(button_block).to include("text-base-content"),
                            "Button must use text-base-content — auto white in dark, auto dark in light"
  end

  it "has type='button' to prevent accidental form submission" do
    button_block = rendered[%r{<button[\s\S]*?data-controller="theme"[\s\S]*?</button>}]
    expect(button_block).to be_present, "Could not find theme toggle button"
    expect(button_block).to include('type="button"')
  end

  it "has an aria-label for accessibility" do
    button_block = rendered[%r{<button[\s\S]*?data-controller="theme"[\s\S]*?</button>}]
    expect(button_block).to be_present, "Could not find theme toggle button"
    expect(button_block).to match(/aria-label="[^"]+"/)
  end

  it "renders the sun icon span" do
    expect(rendered).to have_css(".theme-icon-sun", visible: :all)
  end

  it "renders the moon icon span" do
    expect(rendered).to have_css(".theme-icon-moon", visible: :all)
  end
end
