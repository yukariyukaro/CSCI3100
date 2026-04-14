module Api
  class ListingsController < BaseController
    def index
      render json: { module: "listings", status: "placeholder" }
    end

    def show
      render json: { module: "listings", status: "placeholder", id: params[:id] }
    end

    def create
      render json: { module: "listings", status: "placeholder", action: "create" }, status: :created
    end

    def price_suggestion
      result = Ai::PricingSuggester.new.call(
        name: params[:name],
        description: params[:description],
        condition: params[:condition]
      )

      status = result[:status] == "ok" ? :ok : :unprocessable_content
      render json: result, status: status
    end
  end
end
