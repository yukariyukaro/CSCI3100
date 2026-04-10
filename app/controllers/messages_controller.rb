class MessagesController < ApplicationController
  before_action :authenticate_user!

  def index
    @conversation = find_authorized_conversation
    return unless @conversation

    after_id = params[:after_id].to_i
    scope = @conversation.messages.includes(:sender).order(:id)
    scope = scope.where("id > ?", after_id) if after_id.positive?

    render json: scope.limit(200).map { |m| serialize_message(m) }
  end

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

  def find_authorized_conversation
    conversation = Conversation.find(params[:conversation_id])
    return conversation if conversation.buyer_id == current_user.id || conversation.seller_id == current_user.id

    head :forbidden
    nil
  end

  def serialize_message(message)
    {
      id: message.id,
      content: message.content,
      created_at: message.created_at.strftime("%H:%M"),
      sender_id: message.sender_id,
      sender_name: message.sender.name
    }
  end
end
