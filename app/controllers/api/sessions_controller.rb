module Api
  class SessionsController < BaseController
    def create
      render json: { module: "sessions", status: "placeholder", action: "create" }, status: :created
    end

    def destroy
      head :no_content
    end
  end
end
