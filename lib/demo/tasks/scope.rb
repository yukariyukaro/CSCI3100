module Demo
  module Tasks
    module Scope
      def self.user_ids
        User.where(email: Demo::Tasks::DEMO_EMAILS).pluck(:id)
      end

      def self.products_scope
        Product.where("name LIKE ?", "[DEMO]%")
               .or(Product.where(seller_id: user_ids))
      end

      def self.product_ids
        products_scope.distinct.pluck(:id)
      end

      def self.conversation_ids
        ids = user_ids
        Conversation.where(product_id: product_ids)
                    .or(Conversation.where(buyer_id: ids))
                    .or(Conversation.where(seller_id: ids))
                    .distinct
                    .pluck(:id)
      end

      def self.transaction_ids
        ids = user_ids
        Transaction.where(product_id: product_ids)
                   .or(Transaction.where(buyer_id: ids))
                   .or(Transaction.where(seller_id: ids))
                   .distinct
                   .pluck(:id)
      end
    end
  end
end
