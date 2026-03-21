require "rails_helper"

RSpec.describe User, type: :model do
  it "supports placeholder attributes" do
    user = described_class.new(name: "Placeholder", email: "placeholder@example.com")
    expect(user.name).to eq("Placeholder")
    expect(user.email).to eq("placeholder@example.com")
  end
end
