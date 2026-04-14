require "rails_helper"

RSpec.describe User, type: :model do
  it "is valid with name, email, and password" do
    user = described_class.new(
      name: "Alice",
      email: TestData.unique_email(prefix: "alice"),
      community: default_community,
      password: "password123",
      password_confirmation: "password123"
    )

    expect(user).to be_valid
  end

  it "is invalid without a name" do
    user = described_class.new(
      email: TestData.unique_email(prefix: "alice"),
      password: "password123",
      password_confirmation: "password123"
    )

    expect(user).not_to be_valid
  end

  it "is invalid without an email" do
    user = described_class.new(
      name: "Alice",
      password: "password123",
      password_confirmation: "password123"
    )

    expect(user).not_to be_valid
  end

  it "enforces unique email" do
    email = TestData.unique_email(prefix: "alice")
    described_class.create!(
      name: "Alice",
      email: email,
      community: default_community,
      password: "password123",
      password_confirmation: "password123"
    )
    duplicate_user = described_class.new(
      name: "Bob",
      email: email,
      community: default_community,
      password: "password123",
      password_confirmation: "password123"
    )

    expect(duplicate_user).not_to be_valid
  end
end
