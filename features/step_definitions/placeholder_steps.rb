Given("I visit placeholder page {string}") do |path|
  visit path
end

Then("I should see placeholder text {string}") do |text|
  expect(page).to have_content(text)
end
