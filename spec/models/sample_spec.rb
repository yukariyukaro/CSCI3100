require 'rails_helper'

RSpec.describe "Initial CI Check", type: :model do
  it "should pass this basic math test" do
    expect(1 + 1).to eq(2)
  end
end