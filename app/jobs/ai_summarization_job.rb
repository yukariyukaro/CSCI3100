class AiSummarizationJob < ApplicationJob
  TRANSIENT_ERRORS = [Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNRESET].freeze

  queue_as :default
  retry_on(*TRANSIENT_ERRORS, wait: :polynomially_longer, attempts: 3)

  def perform(product_id)
    product = Product.find_by(id: product_id)
    return unless product

    should_generate = transition_to_generating?(product)
    return unless should_generate

    generate_and_save_summary(product)
  end

  private

  def transition_to_generating?(product)
    product.with_lock do
      product.reload
      return false if terminal_or_running?(product)
      return mark_skipped_status?(product) if invalid_description?(product)
      return skip_without_api_key?(product) if MODELSCOPE_API_KEY.blank?

      mark_generating_status?(product)
    end
  end

  def generate_and_save_summary(product)
    summary = Ai::Summarizer.new(product).fetch_summary_from_modelscope
    return mark_failed!(product) if summary.blank?

    mark_completed!(product, summary)
  rescue *TRANSIENT_ERRORS => e
    handle_transient_failure(product, e)
    raise
  rescue StandardError => e
    handle_terminal_failure(product, e)
  end

  def terminal_or_running?(product)
    %w[completed generating].include?(product.ai_summary_status)
  end

  def invalid_description?(product)
    product.description.blank? || product.description.length < Ai::Summarizer::MIN_LENGTH
  end

  def skip_without_api_key?(product)
    Rails.logger.info("[AI] MODELSCOPE_API_KEY not configured — skipping summary for Product #{product.id}")
    mark_skipped_status?(product)
  end

  def mark_completed!(product, summary)
    product.update!(completed_attributes(summary))
  end

  def mark_failed!(product)
    product.update!(ai_summary_status: "failed")
  end

  def completed_attributes(summary)
    {
      ai_summary: summary,
      ai_model: MODELSCOPE_MODEL_ID,
      ai_summary_status: "completed",
      ai_summary_requested_at: Time.current
    }
  end

  def mark_skipped_status?(product)
    product.update!(ai_summary_status: "skipped")
    false
  end

  def mark_generating_status?(product)
    product.update!(
      ai_summary_status: "generating",
      ai_summary_requested_at: product.ai_summary_requested_at || Time.current
    )
    true
  end

  def handle_transient_failure(product, error)
    product.update!(ai_summary_status: "pending")
    Rails.logger.warn(
      "AiSummarizationJob transient failure for Product #{product.id}: #{error.class} - #{error.message}"
    )
  end

  def handle_terminal_failure(product, error)
    Rails.logger.error("AiSummarizationJob failed for Product #{product.id}: #{error.class} - #{error.message}")
    product.update!(ai_summary_status: "failed")
  end
end
