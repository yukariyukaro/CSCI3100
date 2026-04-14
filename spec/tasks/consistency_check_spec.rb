require "rails_helper"
require "rake"

RSpec.describe "consistency_check:communities" do
  before(:all) do
    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    Rake.application.rake_require("tasks/consistency_check", [Rails.root.join("lib").to_s])
  end

  after(:each) do
    Rake::Task["consistency_check:communities"].reenable
  end

  it "prints OK when data is consistent" do
    community = default_community
    seller = User.create!(name: "Seller", email: TestData.unique_email(prefix: "seller"), password: "password123",
                          password_confirmation: "password123", community: community)
    buyer = User.create!(name: "Buyer", email: TestData.unique_email(prefix: "buyer"), password: "password123",
                         password_confirmation: "password123", community: create_community)
    product = Product.create!(name: "Item", description: "A long enough description.", price: 10, seller: seller)
    conversation = Conversation.create!(product: product, buyer: buyer, seller: seller)
    Transaction.create!(product: product, buyer: buyer, seller: seller, status: :in_progress)
    conversation.messages.create!(sender: buyer, content: "hi")

    expect { Rake::Task["consistency_check:communities"].invoke }.to output("OK\n").to_stdout
  end

  it "exits non-zero when mismatches exist" do
    c1 = create_community(name: "Community A", abbreviation: "CA", slug: "cc-a")
    c2 = create_community(name: "Community B", abbreviation: "CB", slug: "cc-b")
    seller = User.create!(name: "Seller", email: TestData.unique_email(prefix: "seller"), password: "password123",
                          password_confirmation: "password123", community: c1)
    buyer = User.create!(name: "Buyer", email: TestData.unique_email(prefix: "buyer"), password: "password123",
                         password_confirmation: "password123", community: c1)
    product = Product.create!(name: "Item", description: "A long enough description.", price: 10, seller: seller)
    conversation = Conversation.create!(product: product, buyer: buyer, seller: seller)
    conversation.update_columns(community_id: c2.id)

    expect do
      Rake::Task["consistency_check:communities"].invoke
    end.to raise_error(SystemExit)
      .and output(/mismatch/i).to_stdout
  end
end
