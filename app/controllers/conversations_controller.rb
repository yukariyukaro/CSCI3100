class ConversationsController < ApplicationController
  before_action :require_login

  def index
    @conversations = Conversation.for_user(current_user)
                                 .includes(:product, :buyer, :seller, :messages)
                                 .recent_first
  end

  def show
    @conversation = find_authorized_conversation
    @messages = @conversation.messages.includes(:sender).order(created_at: :asc)
    @message = Message.new
  end

  # POST /conversations — called from product#show "Contact Seller" button
  def create
    product = Product.find(params.dig(:conversation, :product_id))
    @conversation = Conversation.find_or_create_by!(
      product: product,
      buyer: current_user,
      seller: product.seller
    )
    redirect_to conversation_path(@conversation)
  rescue ActiveRecord::RecordNotFound
    redirect_to products_path, alert: t("conversations.product_not_found")
  end

  private

  def require_login
    return if logged_in?

    redirect_to new_session_path, alert: t("auth.login_required")
  end

  def find_authorized_conversation
    conversation = Conversation.find(params[:id])
    head :forbidden unless conversation.buyer_id == current_user.id || conversation.seller_id == current_user.id
    conversation
  end
end
