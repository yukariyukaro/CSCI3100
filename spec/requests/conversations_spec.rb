require "rails_helper"

RSpec.describe "Conversations", type: :request do
  describe "GET /conversations" do
    it "redirects to login when not authenticated" do
      get community_conversations_path(community_slug: default_community.slug)
      expect(response).to redirect_to(new_session_path)
    end
  end
end
