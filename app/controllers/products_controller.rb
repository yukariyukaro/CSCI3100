class ProductsController < ApplicationController
  def index
    @query = params[:query].to_s.strip
    @products = load_products

    apply_sorting
  end

  def autocomplete
    query = params[:query].to_s.strip
    if query.length < 2
      render json: []
      return
    end

    cache_key = "autocomplete_#{query.downcase}"
    suggestions = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      Product.suggest(query)
    end

    render json: suggestions
  end

  def show
    @product = Product.includes(active_transaction: :buyer).find(params[:id])

    # Try to get or generate AI summary in background.
    Ai::Summarizer.new(@product).call
  end

  private

  def load_products
    if @query.present?
      if @query.length < 2
        flash.now[:alert] = t("products.search.too_short")
        Product.none
      else
        Product.search(@query).includes(active_transaction: :buyer)
      end
    else
      Product.includes(active_transaction: :buyer).all
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
