module Ai
  # rubocop:disable Metrics/ClassLength
  class Summarizer
    MIN_LENGTH = 20
    REQUEST_TIMEOUT = 60
    TRANSIENT_ERRORS = [Faraday::TimeoutError, Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNRESET].freeze

    def initialize(product)
      @product = product
    end

    def call
      call_sync
    end

    def call_sync(force: false, question: nil)
      normalized_question = normalize_question(question)
      return invalid_input_result if question_provided?(question) && normalized_question.blank?

      preparation_result = prepare_product_for_sync(force, normalized_question)
      return preparation_result if preparation_result

      summary = fetch_summary_from_modelscope(question: normalized_question)
      persist_summary_result(summary, normalized_question)
    end

    # rubocop:disable Metrics/MethodLength
    def fetch_summary_from_modelscope(question: nil)
      clear_error!
      return nil if MODELSCOPE_API_KEY.blank?

      content = request_content(question)
      return handle_empty_response if content.blank?

      content
    rescue *TRANSIENT_ERRORS => e
      Rails.logger.warn("[AI] fetch_summary timeout: #{e.class} - #{e.message}")
      mark_error(:timeout, "AI took too long to respond. Please try again.")
    rescue StandardError => e
      Rails.logger.error("[AI] fetch_summary_from_modelscope failed: #{e.class} - #{e.message}")
      mark_error(:failed, "AI is temporarily unavailable. Please try again.")
    end
    # rubocop:enable Metrics/MethodLength

    private

    def normalize_question(question)
      question.to_s.strip
    end

    def question_provided?(question)
      !question.nil?
    end

    def prepare_product_for_sync(force, normalized_question)
      @product.with_lock do
        @product.reload
        return cached_result(normalized_question) if completed_without_force?(force)

        current_skip_result = skip_result
        return current_skip_result if current_skip_result

        mark_generating!
        nil
      end
    end

    def request_content(question)
      response = Ai::ClientFactory.build(request_timeout: REQUEST_TIMEOUT).chat(
        parameters: chat_parameters(question: question)
      )
      response.dig("choices", 0, "message", "content").to_s.strip
    end

    def handle_empty_response
      mark_error(:empty_response, "AI returned an empty answer. Please try again.")
    end

    def completed_without_force?(force)
      @product.ai_summary_status == "completed" && !force
    end

    def cached_result(normalized_question)
      question = normalized_question.presence || @product.ai_last_question.to_s
      success_result(@product.ai_summary, question)
    end

    def skip_result
      if @product.description.blank? || @product.description.length < MIN_LENGTH
        skip!("Product description is too short for AI to answer reliably.")
      elsif MODELSCOPE_API_KEY.blank?
        skip!("AI service is not configured right now.")
      end
    end

    def completed_attributes(summary, question)
      {
        ai_summary: summary,
        ai_model: MODELSCOPE_MODEL_ID,
        ai_last_question: question.presence,
        ai_summary_status: "completed",
        ai_summary_requested_at: Time.current
      }
    end

    def skip!(message)
      @product.update!(ai_summary_status: "skipped")
      { status: "skipped", ai_summary: nil, message: message, question: nil }
    end

    def mark_generating!
      @product.update!(ai_summary_status: "generating", ai_summary_requested_at: Time.current)
    end

    def persist_summary_result(summary, question)
      if summary.present?
        @product.update!(completed_attributes(summary, question))
        success_result(summary, question)
      else
        @product.update!(ai_summary_status: "failed")
        failure_result(question)
      end
    end

    def success_result(summary, question)
      {
        status: "ok",
        ai_summary: summary,
        message: "AI answered your question.",
        question: question
      }
    end

    def invalid_input_result
      {
        status: "invalid_input",
        ai_summary: nil,
        message: "Please enter a question for AI.",
        question: ""
      }
    end

    def failure_result(question)
      {
        status: "failed",
        ai_summary: nil,
        message: @last_error_message || "AI response failed. Please try again.",
        question: question
      }
    end

    def clear_error!
      @last_error_code = nil
      @last_error_message = nil
    end

    def mark_error(code, message)
      @last_error_code = code
      @last_error_message = message
      nil
    end

    def chat_parameters(question: nil)
      {
        model: MODELSCOPE_MODEL_ID,
        messages: [{ role: "user", content: build_prompt(question: question) }],
        temperature: 0.2,
        max_tokens: 220
      }
    end

    def build_prompt(question: nil)
      question.present? ? question_prompt(question) : summary_prompt
    end

    def question_prompt(question)
      <<~PROMPT
        You are a product assistant for a second-hand marketplace.
        Answer the user's question in concise bullet points.
        Keep the answer grounded in the product information only.
        If uncertain, say "Not enough product information."

        Product name: #{@product.name}
        Product description: #{@product.description}
        User question: #{question}
      PROMPT
    end

    def summary_prompt
      <<~PROMPT
        You are a smart assistant for a second-hand marketplace.
        Read the product description below and extract up to 3 key selling points
        (e.g. condition, accessories included, price advantage, delivery method).
        Output strictly as bullet points, each line starting with ✅, max 20 characters per point.

        Product name: #{@product.name}
        Product description: #{@product.description}
      PROMPT
    end
  end
  # rubocop:enable Metrics/ClassLength
end
