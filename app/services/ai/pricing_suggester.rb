module Ai
  class PricingSuggester
    MIN_LENGTH = 20
    TRANSIENT_ERRORS = [Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNRESET].freeze

    def call(name:, description:, condition:)
      payload = normalize_input(name: name, description: description, condition: condition)
      return payload if payload[:status] != "ok"
      return unavailable_response if MODELSCOPE_API_KEY.blank?

      parse_response(fetch_raw_content(payload))
    rescue *TRANSIENT_ERRORS => e
      Rails.logger.warn("[AI] pricing transient error: #{e.class} - #{e.message}")
      failed_response
    rescue StandardError => e
      Rails.logger.error("[AI] pricing request failed: #{e.class} - #{e.message}")
      failed_response
    end

    private

    def normalize_input(name:, description:, condition:)
      normalized = {
        name: name.to_s.strip,
        description: description.to_s.strip,
        condition: condition.to_s.strip
      }

      return invalid_input_response if normalized[:description].length < MIN_LENGTH

      normalized.merge(status: "ok")
    end

    def build_prompt(payload)
      <<~PROMPT
        You are a pricing assistant for a second-hand marketplace in Hong Kong.
        Estimate a fair listing price in HKD based on the item details.
        Return strict JSON only with this schema:
        {
          "recommended_price": number,
          "min_price": number,
          "max_price": number,
          "reasoning": "short sentence under 120 chars"
        }
        Constraints:
        - min_price <= recommended_price <= max_price
        - all prices > 0

        Product name: #{payload[:name]}
        Condition: #{payload[:condition]}
        Description: #{payload[:description]}
      PROMPT
    end

    def parse_response(raw)
      parsed = JSON.parse(extract_json(raw))
      prices = extract_prices(parsed)
      return failed_response if prices.nil?

      build_success_response(prices, parsed["reasoning"])
    rescue JSON::ParserError
      failed_response
    end

    def fetch_raw_content(payload)
      response = Ai::ClientFactory.build.chat(parameters: chat_parameters(payload))
      response.dig("choices", 0, "message", "content").to_s
    end

    def chat_parameters(payload)
      {
        model: MODELSCOPE_MODEL_ID,
        messages: [{ role: "user", content: build_prompt(payload) }],
        temperature: 0.2,
        max_tokens: 180
      }
    end

    def extract_json(raw)
      return raw unless raw.include?("{") && raw.include?("}")

      raw[raw.index("{")..raw.rindex("}")]
    end

    def extract_prices(parsed)
      min = to_positive_number(parsed["min_price"])
      max = to_positive_number(parsed["max_price"])
      rec = to_positive_number(parsed["recommended_price"])
      return nil if [min, max, rec].any?(&:nil?)
      return nil unless rec.between?(min, max)

      { min: min, max: max, rec: rec }
    end

    def build_success_response(prices, reasoning)
      {
        status: "ok",
        currency: "HKD",
        min_price: prices[:min].round(2),
        max_price: prices[:max].round(2),
        recommended_price: prices[:rec].round(2),
        reasoning: reasoning.to_s.strip.presence || "AI price suggestion generated."
      }
    end

    def to_positive_number(value)
      num = Float(value)
      return nil unless num.positive?

      num
    rescue ArgumentError, TypeError
      nil
    end

    def unavailable_response = { status: "unavailable", message: "AI pricing is unavailable now." }
    def invalid_input_response = { status: "invalid_input", message: "Description must be at least 20 characters." }
    def failed_response = { status: "failed", message: "Failed to generate AI price suggestion." }
  end
end
