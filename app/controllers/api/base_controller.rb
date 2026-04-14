module Api
  class BaseController < ActionController::API
    around_action :reset_current
    before_action :set_community

    private

    def reset_current
      Current.request_id = request.request_id
      yield
    ensure
      Current.reset
    end

    def set_community
      return if params[:community_slug].blank?

      Current.community = Community.fetch_by_slug!(params[:community_slug])
    end
  end
end
