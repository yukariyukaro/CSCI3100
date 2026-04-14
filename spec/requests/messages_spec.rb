require "rails_helper"

RSpec.describe "Messages", type: :request do
  describe "POST /conversations/:conversation_id/messages" do
    it "redirects to login when not authenticated (HTML)" do
      post community_conversation_messages_path(community_slug: default_community.slug, conversation_id: 1),
           params: { message: { content: "Hello" } }
      expect(response).to redirect_to(new_session_path)
    end

    it "returns 401 when not authenticated (JSON)" do
      post community_conversation_messages_path(community_slug: default_community.slug, conversation_id: 1),
           params: { message: { content: "Hello" } },
           headers: { "ACCEPT" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
