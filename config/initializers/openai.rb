# ModelScope Qwen AI configuration (OpenAI-compatible endpoint)
# Set MODELSCOPE_API_KEY in your environment or GitHub Actions Secrets.
# If the key is absent the application boots normally—AI summaries are skipped.
#
# Constants are intentionally NOT frozen here so that:
#   1. dotenv can set ENV before the constant is first evaluated at call time
#   2. RSpec stub_const can override values in tests
MODELSCOPE_API_BASE_URL = ENV.fetch("MODELSCOPE_API_BASE_URL", "https://api-inference.modelscope.cn/v1")
MODELSCOPE_MODEL_ID     = ENV.fetch("MODELSCOPE_MODEL_ID",     "Qwen/Qwen3.5-35B-A3B")
MODELSCOPE_API_KEY      = ENV.fetch("MODELSCOPE_API_KEY",      "")

Rails.application.config.after_initialize do
  if MODELSCOPE_API_KEY.blank? && Rails.env.production?
    Rails.logger.warn("[AI] MODELSCOPE_API_KEY is not set. AI summaries will be skipped.")
  end
end
