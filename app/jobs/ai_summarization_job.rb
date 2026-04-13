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

    # Skip gracefully if no API key is configured (no-AI mode)
    if MODELSCOPE_API_KEY.blank?
      Rails.logger.info("[AI] MODELSCOPE_API_KEY not configured — skipping summary for Product #{product.id}")
      product.update!(ai_summary_status: "skipped")
      return
    end

    product.update!(ai_summary_status: "generating")
    generate_and_save_summary(product)
  end

  private

  def generate_and_save_summary(product)
    summary = Ai::Summarizer.new(product).fetch_summary_from_modelscope
    if summary.present?
      product.update!(
        ai_summary: summary,
        ai_model: MODELSCOPE_MODEL_ID,
        ai_summary_status: "completed",
        ai_summary_requested_at: Time.current
      )
    else
      product.update!(ai_summary_status: "failed")
    end
  rescue StandardError => e
    # Log without exposing the API key
    Rails.logger.error("AiSummarizationJob failed for Product #{product.id}: #{e.class} - #{e.message}")
    product.update!(ai_summary_status: "failed")
  end
end
