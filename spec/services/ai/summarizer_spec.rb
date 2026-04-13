require "rails_helper"

RSpec.describe Ai::Summarizer do
  let(:seller) do
    User.create!(
      name: "Seller",
      email: TestData.unique_email(prefix: "seller"),
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let(:long_description) do
    "Used for a few months, very good condition. Comes with original box and charger. Battery is still at 95%."
  end
  let(:short_description) { "Good condition" }
  let(:product) { Product.create!(name: "Test Phone", description: long_description, price: 500, seller: seller) }
  let(:summarizer) { described_class.new(product) }

  describe "#call" do
    context "when product already has an ai_summary generating or completed" do
      before { product.update!(ai_summary_status: "completed") }

      it "returns nil without enqueueing a job" do
        expect(AiSummarizationJob).not_to receive(:perform_later)
        expect(summarizer.call).to be_nil
      end
    end

    context "when product description is too short" do
      let(:product) { Product.create!(name: "Test Phone", description: short_description, price: 500, seller: seller) }

      it "returns nil without enqueueing a job" do
        expect(AiSummarizationJob).not_to receive(:perform_later)
        expect(summarizer.call).to be_nil
      end
    end

    context "when conditions are met" do
      it "enqueues an AiSummarizationJob" do
        expect(AiSummarizationJob).to receive(:perform_later).with(product.id)
        summarizer.call
      end
    end
  end

  describe "#fetch_summary_from_modelscope" do
    let(:mock_client) { instance_double(OpenAI::Client) }
    # Mock response uses generic content — tests should not depend on specific AI output
    let(:mock_response) do
      {
        "choices" => [
          { "message" => { "content" => "Key selling point 1\nKey selling point 2" } }
        ]
      }
    end

    context "when MODELSCOPE_API_KEY is present" do
      before do
        stub_const("MODELSCOPE_API_KEY", "ms-test-key")
        stub_const("MODELSCOPE_API_BASE_URL", "https://api-inference.modelscope.cn/v1")
        stub_const("MODELSCOPE_MODEL_ID", "Qwen/Qwen3.5-35B-A3B")
        allow(OpenAI::Client).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:chat).and_return(mock_response)
      end

      it "returns a non-blank summary string from the API" do
        result = summarizer.fetch_summary_from_modelscope
        expect(result).to be_present
      end

      it "calls the OpenAI-compatible client with the correct model" do
        expect(mock_client).to receive(:chat).with(
          parameters: hash_including(model: "Qwen/Qwen3.5-35B-A3B")
        ).and_return(mock_response)
        summarizer.fetch_summary_from_modelscope
      end
    end

    context "when MODELSCOPE_API_KEY is blank" do
      before { stub_const("MODELSCOPE_API_KEY", "") }

      it "returns nil without calling the API" do
        expect(OpenAI::Client).not_to receive(:new)
        expect(summarizer.fetch_summary_from_modelscope).to be_nil
      end
    end

    context "when the API raises an error" do
      before do
        stub_const("MODELSCOPE_API_KEY", "ms-test-key")
        stub_const("MODELSCOPE_API_BASE_URL", "https://api-inference.modelscope.cn/v1")
        stub_const("MODELSCOPE_MODEL_ID", "Qwen/Qwen3.5-35B-A3B")
        allow(OpenAI::Client).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:chat).and_raise(StandardError.new("API Timeout"))
      end

      it "catches the error and returns nil" do
        expect(summarizer.fetch_summary_from_modelscope).to be_nil
      end
    end
  end
end
