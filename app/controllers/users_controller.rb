class UsersController < ApplicationController
  before_action :authenticate_user!, only: %i[update]
  before_action :set_and_authorize,  only: %i[update]

  def index
    @users = User.order(:id)
  end

  def show
    @user = User.includes(:community, :products, :bought_transactions, :sold_transactions)
                .find(params[:id])
    @products = @user.products.includes(:community).recent_first

    return unless current_user == @user

    @communities = Community.order(:name)
    load_transactions
    load_manual_intervention_payments
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"),
           status: :not_found, layout: false
  end

  def new
    @user = User.new
    @communities = Community.order(:name)
  end

  def create
    @user = User.new(create_params)
    if @user.save
      session[:user_id] = @user.id
      redirect_to community_products_path(community_slug: @user.community.slug), notice: t("auth.logged_in")
    else
      @communities = Community.order(:name)
      render :new, status: :unprocessable_content
    end
  end

  def update
    return render_sensitive_change_auth_failed if sensitive_change_requires_reauth?

    if @user.update(update_params)
      record_community_change_audit if @user.saved_change_to_community_id?
      redirect_to user_path(@user), notice: t("users.profile.updated")
      return
    end

    load_profile_edit_dependencies
    render :show, status: :unprocessable_content
  end

  private

  def set_and_authorize
    @user = User.find(params[:id])
    return if current_user == @user

    head :forbidden
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"),
           status: :not_found, layout: false
  end

  def create_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :community_id)
  end

  def update_params
    params.require(:user).permit(:name, :avatar, :community_id)
  end

  def sensitive_change_requires_reauth?
    return false unless community_change_requested?

    current_user.authenticate(params[:current_password].to_s) != @user
  end

  def render_sensitive_change_auth_failed
    @user.errors.add(:base, t("users.profile.current_password_invalid"))
    load_profile_edit_dependencies
    render :show, status: :unprocessable_content
  end

  def community_change_requested?
    new_id = update_params[:community_id]
    new_id.present? && new_id.to_s != @user.community_id.to_s
  end

  def record_community_change_audit
    from_id, to_id = @user.saved_change_to_community_id
    AuditEvent.create!(
      community: @user.community,
      user: @user,
      action: "tenant.community_changed",
      metadata: { from_community_id: from_id, to_community_id: to_id },
      request_id: Current.request_id,
      ip: request.remote_ip,
      user_agent: request.user_agent
    )
  end

  def load_profile_edit_dependencies
    @products     = @user.products.includes(:community).recent_first
    @transactions = nil
    @communities = Community.order(:name)
  end

  def load_transactions
    @transactions = (@user.bought_transactions + @user.sold_transactions).sort_by(&:created_at).reverse
  end

  def load_manual_intervention_payments
    @manual_intervention_payments = Payment
                                    .joins(:product_transaction)
                                    .includes(product_transaction: :product)
                                    .where(transactions: { seller_id: @user.id })
                                    .where(status: :manual_intervention_required, resolved_at: nil)
                                    .order(created_at: :desc)
  end
end
