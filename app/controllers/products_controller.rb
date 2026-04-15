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

    cache_key = "autocomplete_#{Current.community&.slug}_#{query.downcase}"
    suggestions = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      Product.suggest(query, scope: current_community_scope(Product).visible_in_catalog)
    end

    render json: suggestions
  end

  def show
    @product = current_community_scope(Product).find(params[:id])
    @conversation = find_chat_conversation
  end

  def ask_ai_about_this
    @product = current_community_scope(Product).find(params[:id])
    @ai_result = Ai::Summarizer.new(@product).call_sync(force: true, question: params[:question])
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
    base = current_community_scope(Product).visible_in_catalog
    return base if @query.blank?

    if @query.length < 2
      flash.now[:alert] = t("products.search.too_short")
      return base.none
    end

    Product.search(@query, scope: base)
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
      format.html { redirect_with_ai_result }
    end
  end

  def render_ai_card_turbo_stream
    render turbo_stream: turbo_stream.replace(
      helpers.dom_id(@product, :ai_summary),
      partial: "products/ai_summary_card",
      locals: { product: @product, ai_result: @ai_result }
    )
  end

  def redirect_with_ai_result
    flash_key = @ai_result[:status] == "ok" ? :notice : :alert
    redirect_to community_product_path(community_slug: Current.community.slug, id: @product.id),
                flash: { flash_key => @ai_result[:message] }
  end
end
