module Ai
  class Summarizer
    # Return early if the description is too short to need a summary
    MIN_LENGTH = 20

    def initialize(product)
      @product = product
    end

    def call
      # Delegate the generation to ActiveJob if not already present/generating
      # Only skip if already completed or currently generating
      # Allow "failed" and "skipped" to be retried
      return if %w[completed generating].include?(@product.ai_summary_status)

      return if @product.description.blank?

      return if @product.description.length < MIN_LENGTH

      # Enqueue background job
      AiSummarizationJob.perform_later(@product.id)
    end

    # Fetch summary from ModelScope Qwen (OpenAI-compatible endpoint).
    # Returns nil if the API key is not configured or the request fails.
    def fetch_summary_from_modelscope
      return nil if MODELSCOPE_API_KEY.blank?

      begin
        client = ::OpenAI::Client.new(
          access_token: MODELSCOPE_API_KEY,
          uri_base: MODELSCOPE_API_BASE_URL,
          request_timeout: 60 # Increased from 20s to 60s for ModelScope API
        )

        response = client.chat(
          parameters: {
            model: MODELSCOPE_MODEL_ID,
            messages: [{ role: "user", content: build_prompt }],
            temperature: 0.3,
            max_tokens: 150
          }
        )

        response.dig("choices", 0, "message", "content")
      rescue StandardError => e
        Rails.logger.error("[AI] fetch_summary_from_modelscope failed: #{e.class} - #{e.message}")
        nil
      end
    end

    private

    def build_prompt
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
