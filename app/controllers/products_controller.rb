class ProductsController < ApplicationController
  def index
    query = params[:query].to_s.strip

    if query.present?
      if query.length < 2
        flash.now[:alert] = "Please enter at least 2 characters to search."
        @products = Product.none
      else
        @products = Product.search(query)
      end
    else
      @products = Product.all
    end

    # Apply Sorting
    case params[:sort]
    when "price_asc"
      @products = @products.order(price: :asc)
    when "price_desc"
      @products = @products.order(price: :desc)
    when "time_desc"
      @products = @products.order(created_at: :desc)
    else
      # 'relevance' or default: 
      # pg_search automatically sorts by relevance if there's a query,
      # but if there's no query, we fallback to time_desc or id
      @products = @products.order(created_at: :desc) unless query.present? && query.length >= 2
    end
  end

  def show
    @product = Product.find(params[:id])
  end
end
