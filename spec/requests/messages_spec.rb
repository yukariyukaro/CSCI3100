require "rails_helper"

RSpec.describe "Messages", type: :request do
  describe "POST /conversations/:conversation_id/messages" do
    it "redirects to login when not authenticated" do
      post "/conversations/1/messages", params: { message: { content: "Hello" } }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
