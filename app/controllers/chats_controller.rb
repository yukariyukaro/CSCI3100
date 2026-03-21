class ChatsController < ApplicationController
  def index
  end

  def show
    @chat_id = params[:id]
  end
end
