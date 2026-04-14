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
    @product = Product.find(params[:id])
    @conversation = find_chat_conversation
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  def ask_ai_about_this
    @product = Product.find(params[:id])
    Ai::Summarizer.new(@product).call_sync(force: true, question: params[:question])
    respond_with_ai_card
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  private

  def find_chat_conversation
    return unless logged_in? && @product.seller.present? && current_user != @product.seller

    Conversation.find_by(product: @product, buyer: current_user, seller: @product.seller)
  end

  def load_products
    if @query.present?
      if @query.length < 2
        flash.now[:alert] = t("products.search.too_short")
        Product.none
      else
        Product.search(@query)
      end
    else
      Product.visible
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

  def respond_with_ai_card
    respond_to do |format|
      format.turbo_stream { render_ai_card_turbo_stream }
      format.html { redirect_to product_path(@product) }
    end
  end

  def render_ai_card_turbo_stream
    render turbo_stream: turbo_stream.replace(
      helpers.dom_id(@product, :ai_summary),
      partial: "products/ai_summary_card",
      locals: { product: @product }
    )
  end
end
