module Ai
  class Summarizer
    MIN_LENGTH = 20
    REQUEST_TIMEOUT = 15

    def initialize(product)
      @product = product
    end

    def call
      call_sync
    end

    def call_sync(force: false, question: nil)
      @product.with_lock do
        @product.reload
        return if @product.ai_summary_status == "completed" && !force
        return skip! if skip_summary?

        mark_generating!
        persist_summary_result(fetch_summary_from_modelscope(question: question))
      end
    end

    def fetch_summary_from_modelscope(question: nil)
      return nil if MODELSCOPE_API_KEY.blank?

      response = Ai::ClientFactory.build(request_timeout: REQUEST_TIMEOUT).chat(
        parameters: chat_parameters(question: question)
      )
      response.dig("choices", 0, "message", "content")
    rescue StandardError => e
      Rails.logger.error("[AI] fetch_summary_from_modelscope failed: #{e.class} - #{e.message}")
      nil
    end

    private

    def skip_summary?
      @product.description.blank? || @product.description.length < MIN_LENGTH || MODELSCOPE_API_KEY.blank?
    end

    def completed_attributes(summary)
      {
        ai_summary: summary,
        ai_model: MODELSCOPE_MODEL_ID,
        ai_summary_status: "completed",
        ai_summary_requested_at: Time.current
      }
    end

    def skip!
      @product.update!(ai_summary_status: "skipped")
    end

    def mark_generating!
      @product.update!(ai_summary_status: "generating", ai_summary_requested_at: Time.current)
    end

    def persist_summary_result(summary)
      if summary.present?
        @product.update!(completed_attributes(summary))
      else
        @product.update!(ai_summary_status: "failed")
      end
    end

    def chat_parameters(question: nil)
      {
        model: MODELSCOPE_MODEL_ID,
        messages: [{ role: "user", content: build_prompt(question: question) }],
        temperature: 0.3,
        max_tokens: 150
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
end
