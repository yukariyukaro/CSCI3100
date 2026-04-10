module Ai
  class Summarizer
    # Return early if the description is too short to need a summary
    MIN_LENGTH = 20

    def initialize(product)
      @product = product
    end

    def call
      # Delegate the generation to ActiveJob if not already present/generating
      return if %w[completed generating].include?(@product.ai_summary_status)
      return if @product.description.blank? || @product.description.length < MIN_LENGTH

      # Enqueue background job
      AiSummarizationJob.perform_later(@product.id) unless Rails.env.test?
    end

    def fetch_summary_from_openai
      response = ::OpenAI::Client.new.chat(
        parameters: {
          model: "gpt-3.5-turbo", # Use an affordable and fast model
          messages: [{ role: "user", content: build_prompt }],
          temperature: 0.3, # Keep it relatively deterministic
          max_tokens: 100
        }
      )
      response.dig("choices", 0, "message", "content")
    end

    private

    def build_prompt
      <<~PROMPT
        你是一个二手交易平台的智能助手。
        请阅读以下商品描述，并提取出最多 3 个最核心的卖点（如新旧程度、配件、价格优势、交易方式等）。
        请严格以 Bullet points (要点) 形式输出，每行以 ✅ 开头，每个要点不超过 15 个字。

        商品名称: #{@product.name}
        商品描述: #{@product.description}
      PROMPT
    end
  end
end
