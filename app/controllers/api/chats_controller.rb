module Api
  class ChatsController < BaseController
    def index
      render json: { module: "chats", status: "placeholder" }
    end

    def show
      render json: { module: "chats", status: "placeholder", id: params[:id] }
    end
  end
end
