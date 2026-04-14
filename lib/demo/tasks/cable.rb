module Demo
  module Tasks
    module Cable
      def self.clear_prefix_if_enabled!
        return unless enabled?

        cfg = cable_config
        return unless redis_adapter?(cfg)

        prefix = channel_prefix(cfg)
        return if prefix.blank?

        deleted = clear_prefix(cfg, prefix)
        Rails.logger.debug { "ActionCable Redis 清理完成：prefix=#{prefix} deleted=#{deleted}" }
      rescue StandardError => e
        warn "ActionCable Redis 清理失败：#{e.class} #{e.message}"
      end

      def self.enabled?
        ENV.fetch("DEMO_RESET_CLEAR_CABLE", "0").to_s == "1"
      end
      private_class_method :enabled?

      def self.cable_config
        Rails.application.config_for(:cable)
      end
      private_class_method :cable_config

      def self.redis_adapter?(cfg)
        cfg.is_a?(Hash) && cfg.fetch("adapter", nil).to_s == "redis"
      end
      private_class_method :redis_adapter?

      def self.channel_prefix(cfg)
        cfg.fetch("channel_prefix", nil).to_s
      end
      private_class_method :channel_prefix

      def self.clear_prefix(cfg, prefix)
        redis = Redis.new(url: redis_url(cfg))
        delete_keys_by_prefix(redis, prefix)
      end
      private_class_method :clear_prefix

      def self.redis_url(cfg)
        cfg.fetch("url", nil).presence || ENV["REDIS_URL"] || "redis://localhost:6379/1"
      end
      private_class_method :redis_url

      def self.delete_keys_by_prefix(redis, prefix)
        deleted = 0
        redis.scan_each(match: "#{prefix}*").each_slice(500) do |keys|
          deleted += redis.del(*keys) if keys.any?
        end
        deleted
      end
      private_class_method :delete_keys_by_prefix

      def self.broadcast_maintenance_notice!(message:)
        payload = { type: "maintenance", message: message, at: Time.current.iso8601 }
        ids = Demo::Tasks::Scope.conversation_ids
        ids.each { |id| ActionCable.server.broadcast("conversation_#{id}", payload) }
        ids.length
      rescue StandardError => e
        warn "ActionCable maintenance broadcast 失败：#{e.class} #{e.message}"
        0
      end
    end
  end
end
