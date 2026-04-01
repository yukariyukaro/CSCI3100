require "rails_helper"

RSpec.describe AiSummarizationJob, type: :job do
  let(:long_description) do
    "Used for a few months, very good condition. Comes with original box and charger. Battery is still at 95%."
  end
  let(:product) { Product.create!(name: "Test Phone", description: long_description, price: 500) }

  describe "#perform" do
    context "when OpenAI calls successfully" do
      let(:mock_client) { instance_double(OpenAI::Client) }
      let(:mock_response) do
        {
          "choices" => [
            {
              "message" => {
                "content" => "✅ 95% Battery\n✅ Original Box"
              }
            }
          ]
        }
      end

      before do
        allow(OpenAI::Client).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:chat).and_return(mock_response)
      end

      it "updates the product with the summary and completed status" do
        described_class.new.perform(product.id)
        product.reload
        expect(product.ai_summary_status).to eq("completed")
        expect(product.ai_summary).to eq("✅ 95% Battery\n✅ Original Box")
        expect(product.ai_summary_requested_at).not_to be_nil
      end
    end

    context "when OpenAI raises an error" do
      let(:mock_client) { instance_double(OpenAI::Client) }

      before do
        allow(OpenAI::Client).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:chat).and_raise(StandardError.new("API Timeout"))
      end

      it "gracefully marks status as failed and logs the error" do
        expect(Rails.logger).to receive(:error).with(/AiSummarizationJob failed for Product #{product.id}: API Timeout/)
        described_class.new.perform(product.id)
        expect(product.reload.ai_summary_status).to eq("failed")
      end
    end
  end
end
