module Demo
  module Tasks
    module Scenario
      def self.ensure!
        seller, buyer = ensure_users!
        products = ensure_products!(seller)

        ensure_chat!(products.fetch(:active), buyer, seller)
        ensure_payments!(products, buyer, seller)
      end

      def self.ensure_users!
        seller = Demo::Tasks::Users.ensure!(email: "demo_seller@example.com", name: "Demo Seller")
        buyer = Demo::Tasks::Users.ensure!(email: "demo_buyer@example.com", name: "Demo Buyer")
        Demo::Tasks::Users.ensure!(email: "demo_user@example.com", name: "Demo User")
        [seller, buyer]
      end
      private_class_method :ensure_users!

      def self.ensure_products!(seller)
        products = Demo::Tasks::Products.ensure_all!(seller: seller)
        products.fetch(:active).update!(sale_status: :active)
        products
      end
      private_class_method :ensure_products!

      def self.ensure_chat!(product, buyer, seller)
        Demo::Tasks::Chat.ensure_conversation_and_messages!(product: product, buyer: buyer, seller: seller)
      end
      private_class_method :ensure_chat!

      def self.ensure_payments!(products, buyer, seller)
        pending_tx = Demo::Tasks::Payments.ensure_pending_transaction!(product: products.fetch(:pending), buyer: buyer,
                                                                       seller: seller)
        Demo::Tasks::Payments.ensure_pending_payment!(transaction: pending_tx)
        Demo::Tasks::Payments.ensure_sold_transaction!(product: products.fetch(:sold), buyer: buyer, seller: seller)
        Demo::Tasks::Payments.ensure_abnormal_payment!(product: products.fetch(:abnormal_payment), buyer: buyer,
                                                       seller: seller)
      end
      private_class_method :ensure_payments!
    end
  end
end
