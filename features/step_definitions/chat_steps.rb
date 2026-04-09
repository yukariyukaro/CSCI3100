# filepath: features/step_definitions/chat_steps.rb
# Note: "a user ... exists" and "I am logged in as ..."
# steps are defined in user_profile_steps.rb and are shared across all features.

# ─── Fixtures ────────────────────────────────────────────────────────────────

Given("a chat product {string} exists for seller {string}") do |name, seller_email|
  seller = User.find_by!(email: seller_email)
  Product.find_or_create_by!(name: name, seller: seller) do |p|
    p.description = "Good condition, used for 6 months, battery at 90%"
    p.price       = 2000
    p.sale_status = :active
  end
end

Given("a conversation exists between Bob and Alice about {string}") do |product_name|
  alice = User.find_by!(email: "alice_chat@example.com")
  bob   = User.find_by!(email: "bob_chat@example.com")
  product = Product.find_by!(name: product_name)
  @conversation = Conversation.find_or_create_by!(product: product, buyer: bob, seller: alice)
end

# ─── Navigation ──────────────────────────────────────────────────────────────

When("I visit the product page for {string}") do |product_name|
  product = Product.find_by!(name: product_name)
  visit product_path(product)
end

When("I visit that conversation") do
  visit conversation_path(@conversation)
end

When("I try to access that conversation directly") do
  visit conversation_path(@conversation)
end

When("I visit the conversations page") do
  visit conversations_path
end

When("I click {string}") do |button_text|
  click_on button_text
end

# ─── Interactions ────────────────────────────────────────────────────────────

When("I fill in the message field with {string}") do |content|
  fill_in "message[content]", with: content
end

# ─── Assertions ──────────────────────────────────────────────────────────────

Then("I should see a {string} link") do |link_text|
  expect(page).to have_link(link_text)
    .or(have_button(link_text))
    .or(have_content(link_text))
end

Then("I should be on a conversation page") do
  expect(current_path).to match(%r{/conversations/\d+})
end

Then("I should see {string} in the chat") do |message_text|
  expect(page).to have_content(message_text)
end

Then("I should see {string} in the conversation list") do |name|
  expect(page).to have_content(name)
end

Then("I should be forbidden") do
  expect(page.status_code).to eq(403)
end

Then("I should see {string}") do |text|
  expect(page).to have_content(text)
end
