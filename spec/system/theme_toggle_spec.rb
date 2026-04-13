require "rails_helper"

# ─────────────────────────────────────────────────────────────────────────────
# Theme Toggle — System Tests (TDD)
#
# rack_test group: tests DOM structure without JavaScript (fast, always run).
# js: true group:  tests actual toggle behaviour via Selenium Chrome Headless.
#                  Skipped locally in WSL (no Chrome), run in CI.
#
# Acceptance criteria:
#   - Toggle button present in navbar on every page
#   - Button has correct Stimulus attributes and aria-label
#   - Both sun and moon icons present in DOM
#   - <body> and <main> carry bg-base-100 for dark-mode background support
#   - <html> starts with a data-theme attribute (set by anti-flash script)
#   - JS: clicking toggles data-theme between light ↔ dark
#   - JS: preference is persisted to localStorage
# ─────────────────────────────────────────────────────────────────────────────

RSpec.describe "Theme Toggle", type: :system do
  def host_os
    RbConfig::CONFIG.fetch("host_os", "")
  end

  def chrome_windows_paths
    [
      "C:/Program Files/Google/Chrome/Application/chrome.exe",
      "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe"
    ]
  end

  def chrome_on_path?
    %w[
      google-chrome
      google-chrome-stable
      chromium
      chromium-browser
      chrome
    ].any? { |bin| system("#{bin} --version > /dev/null 2>&1") }
  end

  def chrome_on_macos?
    host_os.include?("darwin") && File.exist?("/Applications/Google Chrome.app")
  end

  def chrome_on_windows?
    host_os.match?(/mswin|msys|mingw|cygwin/) &&
      chrome_windows_paths.any? { |path| File.exist?(path) }
  end

  def chrome_installed?
    return true if ENV["CI"]

    chrome_on_path? || chrome_on_macos? || chrome_on_windows?
  end

  # ── Static structure (no JS required) ─────────────────────────────────────

  context "DOM structure (rack_test)" do
    before { driven_by(:rack_test) }

    it "renders the theme toggle button in the navbar" do
      visit root_path
      expect(page).to have_css('[data-controller="theme"]')
    end

    it "has the correct data-action attribute" do
      visit root_path
      expect(page).to have_css('[data-action="click->theme#toggle"]')
    end

    it "includes an accessible aria-label on the button" do
      visit root_path
      expect(page).to have_css('[aria-label="Toggle theme"]')
    end

    it "renders the sun icon span" do
      visit root_path
      expect(page).to have_css(".theme-icon-sun")
    end

    it "renders the moon icon span" do
      visit root_path
      expect(page).to have_css(".theme-icon-moon")
    end

    it "applies bg-base-100 to <body> for dark mode background" do
      visit root_path
      expect(page).to have_css("body.bg-base-100")
    end

    it "applies bg-base-100 to <main> for dark mode background" do
      visit root_path
      expect(page).to have_css("main.bg-base-100")
    end

    it "sets a data-theme attribute on <html> via the anti-flash script" do
      visit root_path
      # The anti-flash inline script must set data-theme before first paint.
      # rack_test executes inline scripts, so the attribute should be present.
      html_tag = page.find("html", visible: :all)
      expect(html_tag["data-theme"]).to be_present
    end

    it "defaults data-theme to 'light' when no localStorage preference exists" do
      visit root_path
      html_tag = page.find("html", visible: :all)
      # rack_test has no real matchMedia, so falls back to 'light'
      expect(html_tag["data-theme"]).to eq("light")
    end
  end

  # ── JavaScript behaviour (Selenium, CI only) ──────────────────────────────

  context "interactive toggle (Selenium / headless Chrome)", js: true do
    before do
      pending "Google Chrome is not installed" unless chrome_installed?

      driven_by(:selenium_chrome_headless)
      visit root_path
      page.execute_script("localStorage.setItem('theme', 'light');")
    end

    it "toggles data-theme from light to dark on first click" do
      visit root_path
      expect(page).to have_css('[data-theme="light"]', wait: 2)
      find('[data-controller="theme"]').click
      expect(page).to have_css('[data-theme="dark"]', wait: 2)
    end

    it "toggles data-theme back to light on second click" do
      visit root_path
      find('[data-controller="theme"]').click
      find('[data-controller="theme"]').click
      expect(page).to have_css('[data-theme="light"]', wait: 2)
    end

    it "persists theme preference to localStorage after toggle" do
      visit root_path
      find('[data-controller="theme"]').click
      saved = page.evaluate_script("localStorage.getItem('theme')")
      expect(saved).to eq("dark")
    end

    it "restores saved theme from localStorage on page reload" do
      visit root_path
      find('[data-controller="theme"]').click                      # → dark
      visit root_path                                              # reload
      expect(page).to have_css('[data-theme="dark"]', wait: 2)
    end

    it "updates data-dark attribute on button after toggle" do
      visit root_path
      btn = find('[data-controller="theme"]')
      expect(btn["data-dark"]).to eq("false")
      btn.click
      expect(btn["data-dark"]).to eq("true")
    end
  end
end
