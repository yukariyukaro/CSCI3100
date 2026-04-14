Given("I am on the sign up page") do
  visit new_user_path
end

When("I sign up with valid information") do
  fill_in "Name", with: "Cucumber User"
  fill_in "Email", with: "cucumber_user@example.com"
  select default_community.name, from: "Community"
  fill_in "Password", with: "password123"
  fill_in "Password confirmation", with: "password123"
  click_button "Create Account"
end

Then("I should see authentication success message") do
  expect(page).to have_content("You are logged in.")
end

When("I log out") do
  page.driver.submit :delete, session_path(1), {}
end

Then("I should see logout success message") do
  expect(page).to have_content("You are logged out.")
end

When("I go to the login page") do
  visit new_session_path
end

When("I log in with valid credentials") do
  fill_in "Email", with: "cucumber_user@example.com"
  fill_in "Password", with: "password123"
  click_button "Login"
end
