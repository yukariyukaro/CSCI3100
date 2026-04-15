module Api
  class ProductsController < BaseController
    def index
      products = Product.where(community_id: Current.community.id).includes(:seller).order(created_at: :desc).limit(50)
      render json: {
        community: Current.community.slug,
        products: products.map { |p| serialize_product(p) }
      }
    end

    def show
      product = Product.where(community_id: Current.community.id).includes(:seller).find(params[:id])
      render json: serialize_product(product).merge(community: Current.community.slug)
    end

    # GET /api/:community_slug/products/:id/ai_summary
    # Lightweight polling endpoint for the AI summary card.
    # Returns only the fields the frontend needs; no auth required (summaries are public).
    def ai_summary
      product = Product.find_by(id: params[:id])
      return render json: { error: "not found" }, status: :not_found unless product

      render json: {
        ai_summary_status: product.ai_summary_status,
        ai_summary: product.ai_summary,
        ai_model: product.ai_model,
        ai_last_question: product.ai_last_question,
        ai_summary_requested_at: product.ai_summary_requested_at,
        updated_at: product.updated_at
      }
    end

    private

    def serialize_product(product)
      seller = product.seller
      {
        id: product.id,
        name: product.name,
        description: product.description,
        price: product.price,
        sale_status: product.sale_status,
        created_at: product.created_at.iso8601,
        seller: { id: product.seller_id, name: seller.name }
      }
    end

    # GET /api/products/:id/ai_summary
    # Lightweight polling endpoint for the AI summary card.
    # Returns only the fields the frontend needs; no auth required (summaries are public).
    def ai_summary
      product = Product.find_by(id: params[:id])
      return render json: { error: "not found" }, status: :not_found unless product

      render json: {
        ai_summary_status: product.ai_summary_status,
        ai_summary: product.ai_summary,
        ai_model: product.ai_model,
        ai_last_question: product.ai_last_question,
        ai_summary_requested_at: product.ai_summary_requested_at,
        updated_at: product.updated_at
      }
    end
  end
end
