class ListingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product, only: :destroy
  before_action :authorize_product!, only: :destroy

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

  def destroy
    if @product.active? && @product.update(sale_status: :unlisted)
      redirect_to listings_path, notice: t(".success")
    else
      redirect_to listings_path, alert: t(".failed")
    end
  end

  private

  def set_product
    @product = Product.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  def authorize_product!
    head :forbidden unless @product.seller_id == current_user.id
  end

  def listing_params
    params.require(:product).permit(:name, :description, :price, :condition, :image)
  end
end
