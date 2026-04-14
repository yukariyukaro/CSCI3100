# features/step_definitions/theme_steps.rb

# ─── Navigation ──────────────────────────────────────────────────────────────

Given("I visit the home page") do
  visit root_path
end

Given("I visit the products page") do
  visit community_products_path(community_slug: default_community_slug)
end

# ─── Assertions: button presence ─────────────────────────────────────────────

Then("I should see the theme toggle button") do
  expect(page).to have_css('[data-controller="theme"]'),
                  "Expected a theme toggle button with data-controller=\"theme\" but it was not found"
end

# ─── Assertions: Stimulus data attributes ────────────────────────────────────

Then("the theme toggle button should have data-controller {string}") do |value|
  expect(page).to have_css("[data-controller=\"#{value}\"]"),
                  "Expected theme toggle button with data-controller=\"#{value}\""
end

Then("the theme toggle button should have data-action {string}") do |value|
  expect(page).to have_css("[data-action=\"#{value}\"]"),
                  "Expected theme toggle button with data-action=\"#{value}\""
end

# ─── Assertions: accessibility ───────────────────────────────────────────────

Then("the theme toggle button should have an aria-label {string}") do |label|
  expect(page).to have_css("[aria-label=\"#{label}\"]"),
                  "Expected theme toggle button with aria-label=\"#{label}\""
end

# ─── Assertions: icon spans ──────────────────────────────────────────────────

Then("I should see the sun icon in the theme toggle") do
  expect(page).to have_css(".theme-icon-sun"),
                  "Expected .theme-icon-sun span inside the theme toggle button"
end

Then("I should see the moon icon in the theme toggle") do
  expect(page).to have_css(".theme-icon-moon"),
                  "Expected .theme-icon-moon span inside the theme toggle button"
end

# ─── Assertions: layout ──────────────────────────────────────────────────────

Then("the page body should have the class {string}") do |css_class|
  expect(page).to have_css("body.#{css_class}"),
                  "Expected <body> to have class \"#{css_class}\""
end

Then("the theme toggle button should appear before the user dropdown in the page") do
  html = page.body
  toggle_pos = html.index('data-controller="theme"')
  dropdown_pos = html.index("dropdown-end")
  expect(toggle_pos).not_to be_nil, "Theme toggle button not found in page HTML"
  expect(dropdown_pos).not_to be_nil, "User dropdown not found in page HTML"
  expect(toggle_pos).to be < dropdown_pos,
                        "Expected theme toggle (pos #{toggle_pos}) to appear before user dropdown (pos #{dropdown_pos})"
end
