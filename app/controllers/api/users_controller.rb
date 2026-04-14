module Api
  class UsersController < BaseController
    def index
      render json: { module: "users", status: "placeholder" }
    end

    def show
      render json: { module: "users", status: "placeholder", id: params[:id] }
    end
  end
end
