class AiSummarizationJob < ApplicationJob
  queue_as :default

  def perform(product_id)
    product = Product.find_by(id: product_id)
    return unless product

    # Do not process if it's already generating or generated successfully
    return if %w[generating completed].include?(product.ai_summary_status)

    # Check minimum length
    if product.description.blank? || product.description.length < Ai::Summarizer::MIN_LENGTH
      product.update!(ai_summary_status: "skipped")
      return
    end

    product.update!(ai_summary_status: "generating")
    generate_and_save_summary(product)
  end

  private

  def generate_and_save_summary(product)
    summary = Ai::Summarizer.new(product).fetch_summary_from_openai
    if summary.present?
      product.update!(ai_summary: summary, ai_summary_status: "completed", ai_summary_requested_at: Time.current)
    else
      product.update!(ai_summary_status: "failed")
    end
  rescue StandardError => e
    Rails.logger.error("AiSummarizationJob failed for Product #{product.id}: #{e.message}")
    product.update!(ai_summary_status: "failed")
  end
end
