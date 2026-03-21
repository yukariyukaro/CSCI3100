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
  end
end
