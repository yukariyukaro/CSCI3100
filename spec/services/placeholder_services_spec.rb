require "rails_helper"

RSpec.describe "Placeholder services", type: :model do
  it "returns placeholder from pricing estimator" do
    expect(Pricing::Estimator.new.call).to eq({ status: "placeholder" })
  end

  it "returns placeholder from payments gateway" do
    expect(Payments::Gateway.new.call).to eq({ status: "placeholder" })
  end

  it "returns placeholder from search autocomplete" do
    expect(Search::Autocomplete.new.call).to eq({ status: "placeholder" })
  end
end
