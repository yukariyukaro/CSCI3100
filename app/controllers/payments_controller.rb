class PaymentsController < ApplicationController
  def index
  end

  def new
  end

  def show
    @payment_id = params[:id]
  end

  def create
    redirect_to payments_path
  end
end
