class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?

  include TenantScoped

  before_action :set_locale
  around_action :reset_current
  helper_method :current_community_or_default
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def reset_current
    Current.request_id = request.request_id
    yield
  ensure
    Current.reset
  end

  def authenticate_user!
    return if logged_in?

    respond_to do |format|
      format.html { redirect_to new_session_path, flash: { info: t("auth.login_required") } }
      format.any { head :unauthorized }
    end
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  def render_not_found
    respond_to do |format|
      format.html { render file: Rails.public_path.join("404.html"), status: :not_found, layout: false }
      format.any { head :not_found }
    end
  end

  def set_locale
    session[:locale] = params[:locale] if params[:locale].present?

    I18n.locale = session[:locale].presence_in(I18n.available_locales.map(&:to_s)) || I18n.default_locale
  end
end
