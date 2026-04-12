require "rails_helper"

RSpec.describe Product, type: :model do
  let(:seller) do
    User.create!(
      name: "Seller",
      email: TestData.unique_email(prefix: "seller"),
      password: "password123",
      password_confirmation: "password123"
    )
  end

  describe "validations" do
    it "is valid with a name, description, seller, and price" do
      product = Product.new(name: "Test Product", description: "Test Description long enough", seller: seller, price: 0)
      expect(product).to be_valid
    end

    it "is invalid without a name" do
      product = Product.new(description: "Test Description long enough", seller: seller, price: 0)
      expect(product).not_to be_valid
    end

    it "is invalid without a seller" do
      product = Product.new(name: "Test Product", description: "Test Description long enough", price: 0)
      expect(product).not_to be_valid
    end

    it "is invalid with a negative price" do
      product = Product.new(name: "Test Product", description: "Test Description long enough", seller: seller,
                            price: -0.01)
      expect(product).not_to be_valid
    end

    it "is invalid without a description" do
      product = Product.new(name: "Test Product", seller: seller, price: 0)
      expect(product).not_to be_valid
    end

    it "is invalid when description is shorter than 10 characters" do
      product = Product.new(name: "Test Product", description: "Too short", seller: seller, price: 0)
      expect(product).not_to be_valid
      expect(product.errors[:description]).to be_present
    end

    it "is valid when description is exactly 10 characters" do
      product = Product.new(name: "Test Product", description: "1234567890", seller: seller, price: 0)
      expect(product).to be_valid
    end

    it "defaults price to 0.0 and is valid when price is omitted" do
      product = Product.new(name: "Test Product", description: "Test Description long enough", seller: seller)
      expect(product).to be_valid
      expect(product.price).to eq(0.0)
    end
  end

  describe "image attachment validation" do
    let(:product) do
      Product.new(name: "Test Product", description: "Test Description long enough", seller: seller, price: 10)
    end

    it "is valid without an image attached" do
      expect(product).to be_valid
    end

    it "is invalid when an image larger than 5MB is attached" do
      large_file = fixture_file_upload(
        Rails.root.join("spec/fixtures/files/large_image.jpg"),
        "image/jpeg"
      )
      product.image.attach(large_file)
      expect(product).not_to be_valid
      expect(product.errors[:image]).to be_present
    end

    it "is invalid when a non-image file type is attached" do
      pdf_file = fixture_file_upload(
        Rails.root.join("spec/fixtures/files/test_document.pdf"),
        "application/pdf"
      )
      product.image.attach(pdf_file)
      expect(product).not_to be_valid
      expect(product.errors[:image]).to be_present
    end
  end

  describe "search" do
    before do
      Product.create!(name: "MacBook Pro", description: "Apple laptop", seller: seller, price: 1000)
      Product.create!(name: "iPhone 15", description: "Apple smartphone", seller: seller, price: 800)
      Product.create!(name: "ThinkPad", description: "Lenovo laptop", seller: seller, price: 600)
      Product.create!(name: "Apple Watch", description: "Smart watch by Apple", seller: seller, price: 200)
      Product.create!(name: "Generic Watch", description: "Works with Apple devices", seller: seller, price: 50)

      # For Chinese/English mixed content testing
      Product.create!(
        name: "【急售】95新二手iPhone 14 Pro Max暗夜紫",
        description: "用了大半年，一直带壳贴膜，无任何磕碰。电池健康度89%。支持面交或者邮寄。送几个Casetify手机壳。诚心要的话价格可小刀。",
        seller: seller,
        price: 3200
      )
      Product.create!(
        name: "自用MacBook Air M2 芯片 16+512",
        description: "因为换了Windows打游戏，这台MacBook平时就用来看看B站或者写写代码，非常新。无暗病，键盘无打油。",
        seller: seller,
        price: 7800
      )
    end

    it "returns products matching the name" do
      results = Product.search("MacBook Pro")
      expect(results.map(&:name)).to include("MacBook Pro")
    end

    it "returns products matching the description" do
      results = Product.search("smartphone")
      expect(results.map(&:name)).to include("iPhone 15")
    end

    it "is case-insensitive (e.g., 'iphone' matches 'iPhone')" do
      results = Product.search("iphone")
      expect(results.first.name).to eq("iPhone 15")

      results_upper = Product.search("IPHONE")
      expect(results_upper.first.name).to eq("iPhone 15")
    end

    it "weights name matches higher than description matches (Brand Weighting)" do
      # Searching for "Apple" should return Apple Watch first, because Apple is in the name.
      # Generic Watch should be lower because Apple is only in its description.
      results = Product.search("Apple")
      expect(results.first.name).to eq("Apple Watch")
    end

    it "supports prefix matching (e.g., 'mac' matches 'MacBook')" do
      results = Product.search("mac")
      expect(results.map(&:name)).to include("MacBook Pro")
    end

    it "tolerates typos (e.g., 'ipone' matches 'iPhone')" do
      results = Product.search("ipone")
      expect(results.map(&:name)).to include("iPhone 15")
    end

    it "supports complex mixed Chinese and English queries in name and description" do
      # Test 1: Mixed query matching name (Chinese + English + Number)
      results1 = Product.search("二手iPhone 14")
      expect(results1.map(&:name)).to include("【急售】95新二手iPhone 14 Pro Max暗夜紫")

      # Test 2: Mixed query matching description
      results2 = Product.search("Casetify手机壳")
      expect(results2.map(&:name)).to include("【急售】95新二手iPhone 14 Pro Max暗夜紫")

      # Test 3: Another mixed query for the other product
      results3 = Product.search("MacBook平时就用来")
      expect(results3.map(&:name)).to include("自用MacBook Air M2 芯片 16+512")
    end
  end
end
