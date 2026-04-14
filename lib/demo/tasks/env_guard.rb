module Demo
  module Tasks
    module EnvGuard
      def self.ensure_allowed!(destructive:)
        ensure_not_test!
        return unless destructive
        return unless Rails.env.production?

        require_production_confirmation!
      end

      def self.ensure_non_production!
        ensure_not_test!
        return unless Rails.env.production?

        current_db = current_database
        message = +"拒绝在 production 执行该 demo 任务。"
        message << " current_database=#{current_db}" if current_db.present?
        raise message
      end

      def self.ensure_not_test!
        raise "demo 任务禁止在 test 环境执行" if Rails.env.test?
      end
      private_class_method :ensure_not_test!

      def self.require_production_confirmation!
        current_db = current_database
        Rails.logger.warn("current_database=#{current_db}") if current_db.present?
        return if ENV["CONFIRM_PRODUCTION_DATA_DESTRUCTION"] == "true"

        message = +"拒绝在 production 执行破坏性 demo 任务。"
        message << " current_database=#{current_db}" if current_db.present?
        message << "（如你非常确定，请设置 CONFIRM_PRODUCTION_DATA_DESTRUCTION='true'）"
        raise message
      end
      private_class_method :require_production_confirmation!

      def self.current_database
        ActiveRecord::Base.connection.current_database
      rescue StandardError
        nil
      end
      private_class_method :current_database
    end
  end
end
