require "rails_helper"

RSpec.describe "Products Search", type: :system do
  let(:community) { default_community }
  before do
    driven_by(:rack_test)

    seller = User.create!(
      name: "Seller",
      email: TestData.unique_email(prefix: "seller"),
      community: community,
      password: "password123",
      password_confirmation: "password123"
    )

    Product.create!(name: "MacBook Pro", description: "Apple laptop", seller: seller, price: 1000)
    Product.create!(name: "iPhone 15", description: "Apple smartphone", seller: seller, price: 800)
    Product.create!(name: "ThinkPad", description: "Lenovo laptop", seller: seller, price: 600)
  end

  it "allows users to search products from the community products page" do
    visit community_products_path(community_slug: community.slug)

    fill_in "query", with: "MacBook"
    click_button "搜索"

    expect(page).to have_current_path(community_products_path(community_slug: community.slug), ignore_query: true)
    expect(page).to have_content("MacBook Pro")
    expect(page).not_to have_content("iPhone 15")
  end

  it "allows users to search products from the products index page" do
    visit community_products_path(community_slug: community.slug)

    fill_in "query", with: "laptop"
    click_button "搜索"

    expect(page).to have_content("MacBook Pro")
    expect(page).to have_content("ThinkPad")
    expect(page).not_to have_content("iPhone 15")
  end

  it "allows users to view product details from the search results" do
    visit community_products_path(community_slug: community.slug, query: "iPhone")

    click_link "iPhone 15"

    expect(page).to have_content("iPhone 15")
    expect(page).to have_content("Apple smartphone")
  end
end
