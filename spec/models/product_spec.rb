require "rails_helper"

RSpec.describe Product, type: :model do
  describe "validations" do
    it "is valid with a name and description" do
      product = Product.new(name: "Test Product", description: "Test Description")
      expect(product).to be_valid
    end

    it "is invalid without a name" do
      product = Product.new(description: "Test Description")
      expect(product).not_to be_valid
    end
  end

  describe "search" do
    before do
      Product.create!(name: "MacBook Pro", description: "Apple laptop")
      Product.create!(name: "iPhone 15", description: "Apple smartphone")
      Product.create!(name: "ThinkPad", description: "Lenovo laptop")
      Product.create!(name: "Apple Watch", description: "Smart watch by Apple")
      Product.create!(name: "Generic Watch", description: "Works with Apple devices")

      # For Chinese/English mixed content testing
      Product.create!(
        name: "【急售】95新二手iPhone 14 Pro Max暗夜紫",
        description: "用了大半年，一直带壳贴膜，无任何磕碰。电池健康度89%。支持面交或者邮寄。送几个Casetify手机壳。诚心要的话价格可小刀。"
      )
      Product.create!(
        name: "自用MacBook Air M2 芯片 16+512",
        description: "因为换了Windows打游戏，这台MacBook平时就用来看看B站或者写写代码，非常新。无暗病，键盘无打油。"
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
      expect(results.first.name).to eq("MacBook Pro")
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
