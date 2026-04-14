class SessionsController < ApplicationController
  def new
  end

  def create
    return login_success if authenticated_user

    login_failure
  end

  def destroy
    reset_session
    redirect_to communities_path, notice: t("auth.logged_out")
  end

  private

  def user
    return @user if defined?(@user)

    @user = User.find_by(email: params[:email].to_s.strip.downcase)
  end

  def authenticated_user
    user&.authenticate(params[:password])
  end

  def login_success
    session[:user_id] = user.id
    redirect_to community_products_path(community_slug: user.community.slug), notice: t("auth.logged_in")
  end

  def login_failure
    flash.now[:alert] = t("auth.invalid_credentials")
    @user = User.new
    render :new, status: :unprocessable_content
  end
end
