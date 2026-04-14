require "rails_helper"

RSpec.describe Payments::Providers::Fake do
  describe "#verify_webhook" do
    let(:provider) { described_class.new }
    let(:request) { instance_double(ActionDispatch::Request, request_parameters: request_parameters) }

    context "when event_id is missing" do
      let(:request_parameters) do
        {
          "provider_reference" => "fake_abc123",
          "amount" => "100.0",
          "token" => "t",
          "outcome" => "succeeded"
        }
      end

      it "fills event_id deterministically from provider_reference and outcome" do
        payload = provider.verify_webhook(request)
        expect(payload.fetch("event_id")).to eq("fake_evt_fake_abc123_succeeded")
      end
    end

    context "when event_id is present" do
      let(:request_parameters) do
        {
          "event_id" => "evt_existing",
          "provider_reference" => "fake_abc123",
          "amount" => "100.0",
          "token" => "t",
          "outcome" => "succeeded"
        }
      end

      it "keeps the existing event_id" do
        payload = provider.verify_webhook(request)
        expect(payload.fetch("event_id")).to eq("evt_existing")
      end
    end
  end
end
