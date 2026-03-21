module Api
  class ProductsController < BaseController
    def index
      render json: { module: "products", status: "placeholder" }
    end

    def show
      render json: { module: "products", status: "placeholder", id: params[:id] }
    end
  end
end
