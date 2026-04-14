module Ai
  class ClientFactory
    def self.build(request_timeout: 60)
      ::OpenAI::Client.new(
        access_token: MODELSCOPE_API_KEY,
        uri_base: MODELSCOPE_API_BASE_URL,
        request_timeout: request_timeout
      )
    end
  end
end
