require "rails_helper"

RSpec.describe Ai::Summarizer do
  let(:seller) do
    User.create!(
      name: "Seller",
      email: TestData.unique_email(prefix: "seller"),
      community: default_community,
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

  describe "#call_sync" do
    let(:mock_client) { instance_double(OpenAI::Client) }
    let(:mock_response) do
      {
        "choices" => [
          { "message" => { "content" => "Key selling point 1\nKey selling point 2" } }
        ]
      }
    end

    context "when product already completed" do
      before { product.update!(ai_summary_status: "completed", ai_summary: "already done") }

      it "keeps completed summary unchanged" do
        result = summarizer.call_sync
        expect(result[:status]).to eq("ok")
        expect(product.reload.ai_summary).to eq("already done")
      end
    end

    context "when product description is too short" do
      let(:product) { Product.create!(name: "Test Phone", description: short_description, price: 500, seller: seller) }

      it "marks status as skipped" do
        result = summarizer.call_sync
        expect(result[:status]).to eq("skipped")
        expect(product.reload.ai_summary_status).to eq("skipped")
      end
    end

    context "when api key is blank" do
      before { stub_const("MODELSCOPE_API_KEY", "") }

      it "marks status as skipped" do
        result = summarizer.call_sync
        expect(result[:status]).to eq("skipped")
        expect(product.reload.ai_summary_status).to eq("skipped")
      end
    end

    context "when conditions are met" do
      before do
        stub_const("MODELSCOPE_API_KEY", "ms-test-key")
        allow(Ai::ClientFactory).to receive(:build).and_return(mock_client)
        allow(mock_client).to receive(:chat).and_return(mock_response)
      end

      it "writes completed summary synchronously" do
        result = summarizer.call_sync(question: "Is this in good condition?")
        product.reload
        expect(result[:status]).to eq("ok")
        expect(product.ai_summary_status).to eq("completed")
        expect(product.ai_summary).to include("Key selling point")
        expect(product.ai_last_question).to eq("Is this in good condition?")
      end
    end

    context "when a blank question is submitted explicitly" do
      it "returns invalid_input without calling AI" do
        result = summarizer.call_sync(question: "   ")
        expect(result[:status]).to eq("invalid_input")
        expect(result[:message]).to include("Please enter a question")
      end
    end
  end

  describe "#call" do
    it "delegates to sync flow" do
      expect(summarizer).to receive(:call_sync)
      summarizer.call
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
        allow(Ai::ClientFactory).to receive(:build).and_return(mock_client)
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
        expect(Ai::ClientFactory).not_to receive(:build)
        expect(summarizer.fetch_summary_from_modelscope).to be_nil
      end
    end

    context "when the API raises an error" do
      before do
        stub_const("MODELSCOPE_API_KEY", "ms-test-key")
        stub_const("MODELSCOPE_API_BASE_URL", "https://api-inference.modelscope.cn/v1")
        stub_const("MODELSCOPE_MODEL_ID", "Qwen/Qwen3.5-35B-A3B")
        allow(Ai::ClientFactory).to receive(:build).and_return(mock_client)
        allow(mock_client).to receive(:chat).and_raise(StandardError.new("API Timeout"))
      end

      it "catches the error and returns nil" do
        expect(summarizer.fetch_summary_from_modelscope).to be_nil
      end
    end
  end
end
