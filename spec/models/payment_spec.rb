require "rails_helper"

RSpec.describe Payment, type: :model do
  let(:user) do
    User.create!(
      name: "Buyer",
      email: "payment-user@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  it "is valid with valid attributes" do
    payment = Payment.new(
      user: user,
      transaction_type: :deposit,
      amount: 50.0,
      status: :pending
    )

    expect(payment).to be_valid
  end

  it "requires amount greater than 0" do
    payment = Payment.new(user: user, amount: -10, transaction_type: :deposit, status: :pending)
    expect(payment).not_to be_valid
  end
end
