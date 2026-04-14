class CommunitiesController < ApplicationController
  skip_before_action :set_community, only: %i[root index]
  skip_before_action :authorize_community_access!, only: %i[root index]

  def root
    if logged_in?
      redirect_to community_products_path(community_slug: current_user.community.slug)
    else
      redirect_to communities_path
    end
  end

  def index
    @communities = Community.order(:name)
  end
end
