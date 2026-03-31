class ProductsController < ApplicationController
  def index
    @query = params[:query].to_s.strip
    @products = load_products

    apply_sorting
  end

  def show
    @product = Product.find(params[:id])
  end

  private

  def load_products
    if @query.present?
      if @query.length < 2
        flash.now[:alert] = t("products.search.too_short")
        Product.none
      else
        Product.search(@query)
      end
    else
      Product.all
    end
  end

  def apply_sorting
    case params[:sort]
    when "price_asc"
      @products = @products.order(price: :asc)
    when "price_desc"
      @products = @products.order(price: :desc)
    when "time_desc"
      @products = @products.order(created_at: :desc)
    else
      @products = @products.order(created_at: :desc) unless @query.present? && @query.length >= 2
    end
  end
end
