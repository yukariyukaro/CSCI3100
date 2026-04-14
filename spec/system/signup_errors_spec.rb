require "rails_helper"

RSpec.describe "Signup errors", type: :system do
  before do
    driven_by(:rack_test)
  end

  it "shows errors when email is already taken" do
    community = default_community
    email = TestData.unique_email(prefix: "taken")
    User.create!(name: "Existing", email: email, password: "password123", password_confirmation: "password123",
                 community: community)

    visit new_user_path
    fill_in "Name", with: "New User"
    fill_in "Email", with: email
    select community.name, from: "Community"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"
    click_button "Create Account"

    expect(page).to have_css('[data-testid="signup-errors"]')
    expect(page).to have_content("already been taken").or have_content("taken").or have_content("Email")
  end
end
