class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?

  private

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
end
