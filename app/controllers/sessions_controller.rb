class SessionsController < ApplicationController
  def new
  end

  def create
    if authenticated_user
      session[:user_id] = user.id
      redirect_to root_path, notice: t("auth.logged_in")
    else
      flash.now[:alert] = t("auth.invalid_credentials")
      @user = User.new
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: t("auth.logged_out")
  end

  private

  def user
    return @user if defined?(@user)

    @user = User.find_by(email: params[:email].to_s.strip.downcase)
  end

  def authenticated_user
    user&.authenticate(params[:password])
  end
end
