class MessagesController < ApplicationController
  before_action :require_login

  def create
    @conversation = find_authorized_conversation
    return unless @conversation

    @message = @conversation.messages.build(content: params.dig(:message, :content), sender: current_user)
    @message.save ? reply_success : reply_error
  end

  private

  def reply_success
    respond_to do |format|
      format.html { redirect_to conversation_path(@conversation) }
      format.json { head :ok }
    end
  end

  def reply_error
    respond_to do |format|
      format.html { redirect_to conversation_path(@conversation) }
      format.json { head :unprocessable_content }
    end
  end

  def require_login
    return if logged_in?

    head :unauthorized
  end

  def find_authorized_conversation
    conversation = Conversation.find(params[:conversation_id])
    return conversation if conversation.buyer_id == current_user.id || conversation.seller_id == current_user.id

    head :forbidden
    nil
  end
end
