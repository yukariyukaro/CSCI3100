module TenantScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_community
    before_action :authorize_community_access!
  end

  private

  def set_community
    return if controller_name == "communities"
    return if respond_to?(:devise_controller?) && devise_controller?

    if params[:community_slug].present?
      @target_community = Community.fetch_by_slug!(params[:community_slug])
    elsif logged_in?
      @target_community = current_user.community
    end

    Current.community = @target_community
  end

  def authorize_community_access!
    return unless logged_in?
    return if @target_community.blank?
    return if current_user.community_id == @target_community.id

    return unless forbidden_listing_write_attempt?

    audit_forbidden_listing_write!
    head :forbidden
  end

  def current_community_scope(model)
    raise "Tenant not set for #{controller_name}##{action_name}" if Current.community.nil?

    # Support cross-community trading by showing all products regardless of the current community
    if model == Product
      scope = model.all
      scope = scope.preload(:seller)
    else
      scope = model.where(community_id: Current.community.id)
    end
    scope
  end

  def current_community_or_default
    Current.community || current_user&.community
  end

  def forbidden_listing_write_attempt?
    controller_name == "listings" && action_name.in?(%w[new create])
  end

  def audit_forbidden_listing_write!
    AuditEvent.create!(
      community: @target_community,
      user: current_user,
      action: "tenant.forbidden_listing_write",
      metadata: { controller: controller_name, action: action_name, user_community_id: current_user.community_id },
      request_id: Current.request_id,
      ip: request.remote_ip,
      user_agent: request.user_agent
    )
  end
end
