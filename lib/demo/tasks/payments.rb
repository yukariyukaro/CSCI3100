module Demo
  module Tasks
    module Payments
      def self.prepare!
        seller = Demo::Tasks::Users.ensure!(email: "demo_seller@example.com", name: "Demo Seller")
        buyer = Demo::Tasks::Users.ensure!(email: "demo_buyer@example.com", name: "Demo Buyer")
        products = Demo::Tasks::Products.ensure_all!(seller: seller)

        pending_tx = ensure_pending_transaction!(product: products.fetch(:pending), buyer: buyer, seller: seller)
        ensure_pending_payment!(transaction: pending_tx)
        ensure_abnormal_payment!(product: products.fetch(:abnormal_payment), buyer: buyer, seller: seller)
      end

      def self.ensure_pending_transaction!(product:, buyer:, seller:)
        ensure_seller!(product, seller)

        active_tx = product.active_transaction
        return active_tx if product.pending? && active_tx.present?

        ensure_active!(product) if product.pending? && active_tx.blank?

        ensure_active!(product)
        if product.reserve_by(buyer)
          product.reload
          return Transaction.where(product_id: product.id, status: :in_progress).order(created_at: :desc).first
        end

        create_in_progress_transaction!(product: product, buyer: buyer, seller: seller)
      end

      def self.ensure_sold_transaction!(product:, buyer:, seller:)
        ensure_seller!(product, seller)
        return latest_completed_transaction(product) if product.sold?

        ensure_pending_transaction!(product: product, buyer: buyer, seller: seller)
        product.mark_sold_by(seller)
        latest_completed_transaction(product)
      end

      def self.ensure_pending_payment!(transaction:)
        existing = transaction.payments.pending.where(provider: "fake").order(created_at: :desc).first
        return existing if existing.present?

        transaction.payments.create!(
          amount: transaction.product.price,
          status: :pending,
          provider: "fake",
          provider_reference: "demo_checkout_#{transaction.id}",
          callback_token: SecureRandom.hex(16)
        )
      end

      def self.ensure_abnormal_payment!(product:, buyer:, seller:)
        tx = ensure_pending_transaction!(product: product, buyer: buyer, seller: seller)
        existing = latest_manual_intervention_payment(tx)
        return existing if existing.present?

        create_abnormal_payment!(transaction: tx, product: product)
      end

      def self.latest_completed_transaction(product)
        product.transactions.completed.order(updated_at: :desc).first
      end
      private_class_method :latest_completed_transaction

      def self.latest_manual_intervention_payment(transaction)
        transaction.payments.manual_intervention_required.where(provider: "fake").order(created_at: :desc).first
      end
      private_class_method :latest_manual_intervention_payment

      def self.create_abnormal_payment!(transaction:, product:)
        transaction.payments.create!(
          amount: product.price,
          status: :manual_intervention_required,
          provider: "fake",
          provider_reference: "demo_abnormal_#{transaction.id}",
          callback_token: SecureRandom.hex(16),
          error_details: "amount_mismatch expected=#{product.price} got=#{product.price + 1}"
        )
      end
      private_class_method :create_abnormal_payment!

      def self.ensure_seller!(product, seller)
        product.update!(seller: seller) if product.seller_id != seller.id
      end
      private_class_method :ensure_seller!

      def self.ensure_active!(product)
        product.update!(sale_status: :active) unless product.active?
      end
      private_class_method :ensure_active!

      def self.create_in_progress_transaction!(product:, buyer:, seller:)
        product.transactions.create!(buyer: buyer, seller: seller, status: :in_progress).tap do
          product.update!(sale_status: :pending)
        end
      end
      private_class_method :create_in_progress_transaction!
    end
  end
end
