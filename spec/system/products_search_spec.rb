require "rails_helper"

RSpec.describe "Products Search", type: :system do
  before do
    driven_by(:rack_test)
    Product.create!(name: "MacBook Pro", description: "Apple laptop")
    Product.create!(name: "iPhone 15", description: "Apple smartphone")
    Product.create!(name: "ThinkPad", description: "Lenovo laptop")
  end

  it "allows users to search products from the home page" do
    visit home_path

    fill_in "query", with: "MacBook"
    click_button "Search"

    expect(page).to have_current_path(products_path, ignore_query: true)
    expect(page).to have_content("MacBook Pro")
    expect(page).not_to have_content("iPhone 15")
  end

  it "allows users to search products from the products index page" do
    visit products_path

    fill_in "query", with: "laptop"
    click_button "搜索"

    expect(page).to have_content("MacBook Pro")
    expect(page).to have_content("ThinkPad")
    expect(page).not_to have_content("iPhone 15")
  end

  it "allows users to view product details from the search results" do
    visit products_path(query: "iPhone")

    click_link "iPhone 15"

    expect(page).to have_content("iPhone 15")
    expect(page).to have_content("Apple smartphone")
  end
end
