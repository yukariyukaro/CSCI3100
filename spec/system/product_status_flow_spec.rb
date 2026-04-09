require "rails_helper"

RSpec.describe "Product status flow", type: :system do
  before do
    driven_by(:rack_test)
  end

  let!(:seller) do
    User.create!(
      name: "Seller",
      email: "seller_status_flow@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:buyer) do
    User.create!(
      name: "Buyer",
      email: "buyer_status_flow@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let!(:product) do
    Product.create!(name: "二手iPhone 13", description: "9成新，电池健康度85%", price: 2500, seller: seller)
  end

  def login_as(user)
    visit new_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Login"
  end

  it "allows buyer to reserve then seller to mark sold" do
    login_as(buyer)
    visit product_path(product)

    click_button "预定 / Reserve"
    expect(page).to have_content("Reserved")

    login_as(seller)
    visit product_path(product)

    click_button "标记已售出 / Mark Sold"
    expect(page).to have_content("Sold")
  end

  it "allows buyer to reserve and cancel reservation" do
    login_as(buyer)
    visit product_path(product)

    click_button "预定 / Reserve"
    expect(page).to have_content("Reserved")

    click_button "取消我的预定 / Cancel"
    expect(page).to have_content("Available")
  end
end
