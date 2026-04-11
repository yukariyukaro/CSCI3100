module Demo
  module Tasks
    module Scenario
      def self.ensure!
        seller, buyer = ensure_users!
        products = ensure_products!(seller)

        ensure_chat!(products.fetch(:active), buyer, seller)
        ensure_payments!(products, buyer, seller)
      end

      def self.validate_alignment!
        demo = demo_products_by_key
        errors = []

        validate_presence!(demo, errors)
        validate_active_product!(demo[:active], errors)
        validate_pending_product!(demo[:pending], errors)
        validate_sold_product!(demo[:sold], errors)
        validate_abnormal_payment_product!(demo[:abnormal_payment], errors)

        raise "demo 状态校验失败：\n- #{errors.join("\n- ")}" if errors.any?
      end

      def self.demo_products_by_key
        names_by_key = Demo::Tasks::PRODUCT_DEFINITIONS.transform_values { |v| v.fetch(:name) }
        products_by_name = Product.where(name: names_by_key.values).index_by(&:name)
        names_by_key.transform_values { |name| products_by_name[name] }
      end
      private_class_method :demo_products_by_key

      def self.validate_presence!(demo, errors)
        errors << "缺少 active demo 商品" if demo[:active].blank?
        errors << "缺少 pending demo 商品" if demo[:pending].blank?
        errors << "缺少 sold demo 商品" if demo[:sold].blank?
        errors << "缺少 abnormal_payment demo 商品" if demo[:abnormal_payment].blank?
      end
      private_class_method :validate_presence!

      def self.validate_active_product!(product, errors)
        return if product.blank?

        errors << "active 商品 sale_status 不为 active（#{product.sale_status}）" unless product.active?
        errors << "active 商品存在进行中交易（tx_id=#{product.active_transaction&.id}）" if product.active_transaction.present?
      end
      private_class_method :validate_active_product!

      def self.validate_pending_product!(product, errors)
        return if product.blank?

        errors << "pending 商品 sale_status 不为 pending（#{product.sale_status}）" unless product.pending?
        errors << "pending 商品缺少进行中交易" if product.active_transaction.blank?
      end
      private_class_method :validate_pending_product!

      def self.validate_sold_product!(product, errors)
        return if product.blank?

        errors << "sold 商品 sale_status 不为 sold（#{product.sale_status}）" unless product.sold?
        completed_tx = product.transactions.completed.order(updated_at: :desc).first
        errors << "sold 商品缺少 completed 交易" if completed_tx.blank?
      end
      private_class_method :validate_sold_product!

      def self.validate_abnormal_payment_product!(product, errors)
        return if product.blank?

        errors << "abnormal_payment 商品 sale_status 不为 pending（#{product.sale_status}）" unless product.pending?
        tx = product.active_transaction
        errors << "abnormal_payment 商品缺少进行中交易" if tx.blank?
        return if tx.blank?

        payment = tx.payments.manual_intervention_required.order(created_at: :desc).first
        errors << "abnormal_payment 缺少 manual_intervention_required 支付记录" if payment.blank?
      end
      private_class_method :validate_abnormal_payment_product!

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
