require "rails_helper"

RSpec.describe Ai::PricingSuggester do
  describe "#call" do
    let(:service) { described_class.new }

    context "when api key is missing" do
      before { stub_const("MODELSCOPE_API_KEY", "") }

      it "returns unavailable status" do
        result = service.call(
          name: "Used iPad",
          description: "In good condition with charger and case included.",
          condition: "Good"
        )

        expect(result[:status]).to eq("unavailable")
      end
    end

    context "when input is invalid" do
      it "returns invalid_input status for short description" do
        result = service.call(name: "Item", description: "short", condition: "Good")
        expect(result[:status]).to eq("invalid_input")
      end
    end

    context "when model returns valid json" do
      let(:client) { instance_double(OpenAI::Client) }

      before do
        stub_const("MODELSCOPE_API_KEY", "ms-test-key")
        allow(Ai::ClientFactory).to receive(:build).and_return(client)
        content = <<~JSON.squish
          {"recommended_price":1200,"min_price":1000,"max_price":1300,"reasoning":"Good condition and bundled accessories."}
        JSON
        allow(client).to receive(:chat).and_return(
          { "choices" => [{ "message" => { "content" => content } }] }
        )
      end

      it "returns normalized pricing result" do
        result = service.call(
          name: "Used iPad",
          description: "In good condition with charger and case included.",
          condition: "Good"
        )

        expect(result[:status]).to eq("ok")
        expect(result[:recommended_price]).to eq(1200.0)
        expect(result[:min_price]).to eq(1000.0)
        expect(result[:max_price]).to eq(1300.0)
      end
    end
  end
end
