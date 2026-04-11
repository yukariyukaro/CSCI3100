module Demo
  module Tasks
    module Chat
      def self.reset!
        seller = Demo::Tasks::Users.ensure!(email: "demo_seller@example.com", name: "Demo Seller")
        buyer = Demo::Tasks::Users.ensure!(email: "demo_buyer@example.com", name: "Demo Buyer")
        products = Demo::Tasks::Products.ensure_all!(seller: seller)

        cleanup!
        ensure_conversation_and_messages!(product: products.fetch(:active), buyer: buyer, seller: seller)
      end

      def self.cleanup!
        conversation_ids = Demo::Tasks::Scope.conversation_ids
        Message.where(conversation_id: conversation_ids).delete_all
        Conversation.where(id: conversation_ids).delete_all
      end

      def self.ensure_conversation_and_messages!(product:, buyer:, seller:)
        conversation = Conversation.find_or_create_by!(product: product, buyer: buyer) do |c|
          c.seller = seller
        end

        conversation.update!(seller: seller) if conversation.seller_id != seller.id
        return conversation if conversation.messages.exists?

        Message.create!(conversation: conversation, sender: buyer, content: "你好，这个还在吗？")
        Message.create!(conversation: conversation, sender: seller, content: "在的，可以直接预定/支付。")
        conversation
      end
    end
  end
end
