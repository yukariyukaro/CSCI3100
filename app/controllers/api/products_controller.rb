module Api
  class ProductsController < BaseController
    def index
      render json: { module: "products", status: "placeholder" }
    end

    def show
      render json: { module: "products", status: "placeholder", id: params[:id] }
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
