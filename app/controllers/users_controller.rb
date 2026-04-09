class UsersController < ApplicationController
  before_action :authenticate_user!, only: %i[update]
  before_action :set_and_authorize,  only: %i[update]

  def index
    @users = User.order(:id)
  end

  def show
    @user = User.includes(:products, :bought_transactions, :sold_transactions)
                .find(params[:id])
    @products = @user.products.recent_first

    return unless current_user == @user

    load_transactions
    load_manual_intervention_payments
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"),
           status: :not_found, layout: false
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(create_params)
    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: t("auth.logged_in")
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @user.update(update_params)
      redirect_to user_path(@user), notice: t("users.profile.updated")
    else
      @products     = @user.products.recent_first
      @transactions = nil
      render :show, status: :unprocessable_content
    end
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
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def update_params
    params.require(:user).permit(:name, :avatar)
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
