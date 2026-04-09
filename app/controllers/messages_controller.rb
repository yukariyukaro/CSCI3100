class MessagesController < ApplicationController
  before_action :require_login

  def create
    @conversation = find_authorized_conversation
    @message = @conversation.messages.build(content: params.dig(:message, :content),
                                            sender: current_user)
    if @message.save
      # ActionCable broadcast is triggered by after_create_commit in Message model.
      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def require_login
    return if logged_in?

    head :unauthorized
  end

  def find_authorized_conversation
    conversation = Conversation.find(params[:conversation_id])
    unless conversation.buyer_id == current_user.id || conversation.seller_id == current_user.id
      head :forbidden
    end
    conversation
  end
end
