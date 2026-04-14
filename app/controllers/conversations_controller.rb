class ConversationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @conversations = current_community_scope(Conversation)
                     .for_user(current_user)
                     .includes(:product, :buyer, :seller, :messages)
                     .recent_first
  end

  def show
    @conversation = find_authorized_conversation
    return unless @conversation

    @messages = @conversation.messages.includes(:sender).order(created_at: :asc)
    @message = Message.new
  end

  # POST /conversations — called from product#show "Contact Seller" button
  def create
    product = current_community_scope(Product).find(params.dig(:conversation, :product_id))
    @conversation = Conversation.find_or_create_by!(
      product: product,
      buyer: current_user,
      seller: product.seller
    )
    redirect_to community_conversation_path(community_slug: @conversation.community.slug, id: @conversation)
  rescue ActiveRecord::RecordNotFound
    redirect_to community_products_path(community_slug: Current.community&.slug),
                alert: t("conversations.product_not_found")
  end

  private

  def find_authorized_conversation
    conversation = current_community_scope(Conversation).find(params[:id])
    return conversation if conversation.buyer_id == current_user.id || conversation.seller_id == current_user.id

    head :forbidden
    nil
  end
end
