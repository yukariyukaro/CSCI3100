require "rails_helper"

RSpec.describe "Messages", type: :request do
  describe "POST /conversations/:conversation_id/messages" do
    it "redirects to login when not authenticated (HTML)" do
      post "/conversations/1/messages", params: { message: { content: "Hello" } }
      expect(response).to redirect_to(new_session_path)
    end

    it "returns 401 when not authenticated (JSON)" do
      post "/conversations/1/messages",
           params: { message: { content: "Hello" } },
           headers: { "ACCEPT" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
