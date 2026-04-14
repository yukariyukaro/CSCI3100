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
  visit community_product_path(community_slug: product.community.slug, id: product)
end

When("I visit that conversation") do
  visit community_conversation_path(community_slug: @conversation.community.slug, id: @conversation)
end

When("I try to access that conversation directly") do
  visit community_conversation_path(community_slug: @conversation.community.slug, id: @conversation)
end

When("I visit the conversations page") do
  visit community_conversations_path(community_slug: default_community_slug)
end

When("I click {string}") do |button_text|
  case button_text
  when "联系卖家"
    node = find('[data-testid="contact-seller"]', match: :first)
    if node.tag_name == "a"
      node.click
    else
      node.find("a, button, input[type=submit]", match: :first).click
    end
  when "Send"
    find('[data-testid="send-message"]').click
  else
    click_on button_text
  end
end

# ─── Interactions ────────────────────────────────────────────────────────────

When("I fill in the message field with {string}") do |content|
  fill_in "message[content]", with: content
end

# ─── Assertions ──────────────────────────────────────────────────────────────

Then("I should see a {string} link") do |link_text|
  expect(page).to have_css("a, button, input[type=submit]", text: link_text)
end

Then("I should be on a conversation page") do
  expect(current_path).to match(%r{/#{Regexp.escape(default_community_slug)}/conversations/\d+})
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
