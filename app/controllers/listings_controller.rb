class ListingsController < ApplicationController
  before_action :authenticate_user!

  def index
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(listing_params)
    @product.seller = current_user

    if @product.save
      redirect_to product_path(@product), notice: t(".success")
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def listing_params
    params.require(:product).permit(:name, :description, :price, :condition, :image)
  end
end
