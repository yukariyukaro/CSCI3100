require "rails_helper"

RSpec.describe Ai::Summarizer do
  let(:long_description) do
    "Used for a few months, very good condition. Comes with original box and charger. Battery is still at 95%."
  end
  let(:short_description) { "Good condition" }
  let(:product) { Product.create!(name: "Test Phone", description: long_description, price: 500) }
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
      let(:product) { Product.create!(name: "Test Phone", description: short_description, price: 500) }

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
end
