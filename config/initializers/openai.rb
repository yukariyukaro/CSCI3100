OpenAI.configure do |config|
  config.access_token = ENV.fetch("OPENAI_API_KEY", "")
  # Optional: config.organization_id = ENV.fetch("OPENAI_ORGANIZATION_ID", "")
  config.request_timeout = 10 # Provide a reasonable timeout
end
