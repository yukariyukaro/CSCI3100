module Api
  class PaymentsController < BaseController
    def index
      render json: { module: "payments", status: "placeholder" }
    end

    def show
      render json: { module: "payments", status: "placeholder", id: params[:id] }
    end

    def create
      render json: { module: "payments", status: "placeholder", action: "create" }, status: :created
    end
  end
end
