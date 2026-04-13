require "rails_helper"

RSpec.describe AiSummarizationJob, type: :job do
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
  let(:product) { Product.create!(name: "Test Phone", description: long_description, price: 500, seller: seller) }

  describe "#perform" do
    context "when ModelScope API key is present and call succeeds" do
      let(:mock_client) { instance_double(OpenAI::Client) }
      # Generic content — tests verify structure, not AI-generated wording
      let(:mock_response) do
        {
          "choices" => [
            { "message" => { "content" => "Selling point A\nSelling point B" } }
          ]
        }
      end

      before do
        stub_const("MODELSCOPE_API_KEY", "ms-test-key")
        stub_const("MODELSCOPE_MODEL_ID", "Qwen/Qwen3.5-35B-A3B")
        allow(OpenAI::Client).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:chat).and_return(mock_response)
      end

      it "updates the product with a non-blank summary, ai_model, and completed status" do
        described_class.new.perform(product.id)
        product.reload
        expect(product.ai_summary_status).to eq("completed")
        expect(product.ai_summary).to be_present
        expect(product.ai_model).to eq("Qwen/Qwen3.5-35B-A3B")
        expect(product.ai_summary_requested_at).not_to be_nil
      end

      it "is idempotent — does not re-generate for a completed product" do
        product.update!(ai_summary_status: "completed", ai_summary: "✅ Already done")
        expect(OpenAI::Client).not_to receive(:new)
        described_class.new.perform(product.id)
        expect(product.reload.ai_summary).to eq("✅ Already done")
      end
    end

    context "when MODELSCOPE_API_KEY is blank (no-AI mode)" do
      before { stub_const("MODELSCOPE_API_KEY", "") }

      it "skips summary generation and sets status to skipped" do
        expect(OpenAI::Client).not_to receive(:new)
        described_class.new.perform(product.id)
        expect(product.reload.ai_summary_status).to eq("skipped")
      end
    end

    context "when ModelScope API raises an error" do
      let(:mock_client) { instance_double(OpenAI::Client) }

      before do
        stub_const("MODELSCOPE_API_KEY", "ms-test-key")
        stub_const("MODELSCOPE_MODEL_ID", "Qwen/Qwen3.5-35B-A3B")
        allow(OpenAI::Client).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:chat).and_raise(StandardError.new("API Timeout"))
      end

      it "marks status as failed and logs the error without exposing the key" do
        expect(Rails.logger).to receive(:error).with(
          /\[AI\] fetch_summary_from_modelscope failed: StandardError - API Timeout/
        )
        described_class.new.perform(product.id)
        expect(product.reload.ai_summary_status).to eq("failed")
      end
    end

    context "when product description is too short" do
      let(:product) do
        # Description is >= 10 chars (passes model validation) but < MIN_LENGTH (20)
        Product.create!(name: "Short", description: "Good item.", price: 10, seller: seller)
      end

      it "marks status as skipped without calling the API" do
        stub_const("MODELSCOPE_API_KEY", "ms-test-key")
        expect(OpenAI::Client).not_to receive(:new)
        described_class.new.perform(product.id)
        expect(product.reload.ai_summary_status).to eq("skipped")
      end
    end
  end
end
