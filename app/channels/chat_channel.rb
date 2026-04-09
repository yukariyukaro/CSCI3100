class ChatChannel < ApplicationCable::Channel
  def subscribed
    conversation = Conversation.find_by(id: params[:conversation_id])

    if conversation && authorized?(conversation)
      stream_from "conversation_#{conversation.id}"
    else
      reject
    end
  end

  def unsubscribed
    stop_all_streams
  end

  private

  def authorized?(conversation)
    current_user &&
      (conversation.buyer_id == current_user.id ||
       conversation.seller_id == current_user.id)
  end
end
