require_relative "db_guard_failures"

module DbGuard
  TEST_DB_NAME = "cuhk_marketplace_test".freeze

  def self.prepare_env!
    return unless ENV["RAILS_ENV"] == "test"
    return if ENV["CI"] || present?(ENV.fetch("TEST_DATABASE_URL", nil))

    ENV.delete("DATABASE_URL")
  end

  def self.check_pending!
    return unless defined?(ActiveRecord::Migration)

    ensure_safe_test_database!
    check_pending_migrations!
  rescue ActiveRecord::PendingMigrationError => e
    DbGuardFailures.pending_migrations!(e.message.to_s.strip)
  rescue StandardError => e
    handle_connection_error!(e)
  end

  def self.handle_connection_error!(error)
    if error.is_a?(ActiveRecord::ConnectionNotEstablished)
      DbGuardFailures.connection_failed!(error.message, connection_summary)
    end

    if defined?(PG::ConnectionBad) && error.is_a?(PG::ConnectionBad)
      DbGuardFailures.connection_failed!(error.message, connection_summary)
    end

    raise error
  end
  private_class_method :handle_connection_error!

  def self.check_pending_migrations!
    if ActiveRecord::Migration.respond_to?(:check_pending!)
      ActiveRecord::Migration.check_pending!
    elsif ActiveRecord::Migration.respond_to?(:check_pending_migrations)
      ActiveRecord::Migration.check_pending_migrations
    elsif ActiveRecord::Migration.respond_to?(:check_all_pending!)
      ActiveRecord::Migration.check_all_pending!
    elsif ActiveRecord::Migration.respond_to?(:maintain_test_schema!)
      ActiveRecord::Migration.maintain_test_schema!
    end
  end

  def self.ensure_safe_test_database!
    return unless defined?(Rails) && Rails.env.test?

    db_name = current_db_name.to_s
    DbGuardFailures.unknown_db!(connection_summary) if db_name.empty?

    downcased = db_name.downcase
    if downcased.include?("production") || downcased.include?("development")
      DbGuardFailures.suspect_db_name!(db_name, connection_summary)
    end

    DbGuardFailures.non_test_db!(db_name, connection_summary) unless db_name.end_with?("_test")
  end

  def self.connection_summary
    cfg = safe_connection_config
    lines = ["ActiveRecord connection:"]
    add_summary_line(lines, cfg, :adapter)
    add_summary_line(lines, cfg, :database)
    add_summary_line(lines, cfg, :host, optional: true)
    add_summary_line(lines, cfg, :port, optional: true)
    add_summary_line(lines, cfg, :username, optional: true)
    lines.join("\n")
  end

  def self.add_summary_line(lines, cfg, key, optional: false)
    value = cfg_value(cfg, key)
    return if optional && (value.nil? || value.to_s.empty?)

    lines << "  #{key}=#{value}"
  end
  private_class_method :add_summary_line

  def self.cfg_value(cfg, key)
    cfg[key] || cfg[key.to_s]
  end
  private_class_method :cfg_value

  def self.safe_connection_config
    return {} unless defined?(ActiveRecord::Base)

    cfg = ActiveRecord::Base.connection_db_config
    raw = cfg&.configuration_hash || {}
    sanitize_connection_config(raw)
  rescue StandardError
    {}
  end

  def self.sanitize_connection_config(raw)
    sanitized = raw.dup
    sanitized.delete(:password)
    sanitized.delete("password")
    sanitized.delete(:url)
    sanitized.delete("url")
    sanitized
  end
  private_class_method :sanitize_connection_config

  def self.current_db_name
    return unless defined?(ActiveRecord::Base)

    cfg = ActiveRecord::Base.connection_db_config
    cfg&.database
  rescue StandardError
    nil
  end

  def self.present?(value)
    value && !value.to_s.empty?
  end
end
