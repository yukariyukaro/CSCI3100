# filepath: features/step_definitions/user_profile_steps.rb

# ─── Background helpers ──────────────────────────────────────────────────────

Given("a user {string} exists with email {string} and password {string}") do |name, email, password|
  User.find_or_create_by!(email: email) do |u|
    u.name                  = name
    u.password              = password
    u.password_confirmation = password
  end
end

Given("I am not logged in") do
  # No session setup — Capybara starts fresh
end

Given("I am logged in as {string} with password {string}") do |email, password|
  visit new_session_path
  fill_in "Email",    with: email
  fill_in "Password", with: password
  click_button "Login"
end

# ─── Navigation ──────────────────────────────────────────────────────────────

When("I visit Alice's profile page") do
  alice = User.find_by!(email: "alice@example.com")
  visit user_path(alice)
end

# ─── Product fixture ─────────────────────────────────────────────────────────

Given("Alice has a product {string} with description {string} and status {string}") do |name, description, status|
  alice = User.find_by!(email: "alice@example.com")
  Product.create!(
    name: name,
    description: description,
    seller: alice,
    sale_status: status.to_sym
  )
end

# ─── Transaction fixture ─────────────────────────────────────────────────────

Given("Alice has a completed transaction for product {string} with Bob as buyer") do |product_name|
  alice = User.find_by!(email: "alice@example.com")
  bob   = User.find_by!(email: "bob@example.com")
  product = Product.find_or_create_by!(name: product_name) do |p|
    p.description = "#{product_name} description"
    p.seller      = alice
    p.sale_status = :sold
  end
  Transaction.find_or_create_by!(product: product) do |t|
    t.buyer  = bob
    t.seller = alice
    t.status = :completed
  end
end

# ─── Assertions — profile elements ──────────────────────────────────────────

Then("I should see Alice's name {string}") do |name|
  expect(page).to have_content(name)
end

Then("I should see Alice's avatar or placeholder") do
  alice = User.find_by!(email: "alice@example.com")
  has_avatar_img = page.has_css?("img[alt*='avatar']") ||
                   page.has_css?("img[alt*='Avatar']") ||
                   page.has_css?("img[alt*='#{alice.name}']") ||
                   page.has_css?(".avatar") ||
                   page.has_css?("[data-testid='avatar']")
  expect(has_avatar_img).to be true
end

Then("I should see the {string} section") do |section_name|
  expect(page).to have_content(section_name)
end

Then("I should see {string} in the items list") do |product_name|
  expect(page).to have_content(product_name)
end

Then("I should see the {string} tab or section") do |label|
  expect(page).to have_content(label)
end

Then("I should see {string} in the transactions list") do |product_name|
  expect(page).to have_content(product_name)
end

Then("I should see the sold count {string}") do |count|
  expect(page).to have_content(count)
end

# ─── Assertions — transaction privacy ────────────────────────────────────────

Then("I should not see the transaction details") do
  expect(page).not_to have_content("completed")
  expect(page).not_to have_content("in_progress")
end

Then("I should see a message to log in to view transactions") do
  has_msg = page.has_content?("Log in") ||
            page.has_content?("log in") ||
            page.has_content?("login") ||
            page.has_content?("Login")
  expect(has_msg).to be true
end

# ─── Avatar upload ───────────────────────────────────────────────────────────

When("I upload a valid avatar image") do
  # Create a minimal valid JPEG fixture if it doesn't exist yet
  fixture_path = Rails.root.join("spec/fixtures/files/avatar.jpg")
  FileUtils.mkdir_p(File.dirname(fixture_path))
  unless File.exist?(fixture_path)
    # Minimal 1×1 white JPEG bytes
    File.binwrite(fixture_path, [
      0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
      0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
      0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
      0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
      0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
      0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
      0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
      0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
      0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00,
      0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
      0x09, 0x0A, 0x0B, 0xFF, 0xC4, 0x00, 0xB5, 0x10, 0x00, 0x02, 0x01, 0x03,
      0x03, 0x02, 0x04, 0x03, 0x05, 0x05, 0x04, 0x04, 0x00, 0x00, 0x01, 0x7D,
      0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F, 0x00, 0xFB, 0xD3,
      0xFF, 0xD9
    ].pack("C*"))
  end
  attach_file("user_avatar", fixture_path, make_visible: true)
  click_button "Save"
end

Then("I should see a success notice") do
  has_notice = page.has_css?(".alert") ||
               page.has_css?(".notice") ||
               page.has_css?("[role='alert']") ||
               page.has_content?("updated") ||
               page.has_content?("saved") ||
               page.has_content?("Profile updated") ||
               page.has_content?("success")
  expect(has_notice).to be true
end

Then("I should be on Alice's profile page") do
  alice = User.find_by!(email: "alice@example.com")
  expect(current_path).to eq(user_path(alice))
end
