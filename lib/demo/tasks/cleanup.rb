module Demo
  module Tasks
    module Cleanup
      def self.deep_cleanup!
        ActiveRecord::Base.transaction do
          Demo::Tasks::Chat.cleanup!
          cleanup_transactions_and_payments!
          Demo::Tasks::Products.reset_statuses_to_active!
        end
      end

      def self.cleanup_transactions_and_payments!
        transaction_ids = Demo::Tasks::Scope.transaction_ids
        Payment.where(transaction_id: transaction_ids).delete_all
        Transaction.where(id: transaction_ids).delete_all
      end
      private_class_method :cleanup_transactions_and_payments!
    end
  end
end
