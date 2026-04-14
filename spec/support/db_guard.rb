require_relative "db_guard_failures"
require_relative "db_guard_connection"

module DbGuard
  TEST_DB_NAME = "cuhk_marketplace_test".freeze

  def self.prepare_env!
    return unless ENV["RAILS_ENV"] == "test"
    return if ENV["CI"] || ENV.fetch("TEST_DATABASE_URL", "").to_s != ""

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
      DbGuardFailures.connection_failed!(error.message, DbGuardConnection.connection_summary)
    end

    if defined?(PG::ConnectionBad) && error.is_a?(PG::ConnectionBad)
      DbGuardFailures.connection_failed!(error.message, DbGuardConnection.connection_summary)
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

    db_name = DbGuardConnection.current_db_name.to_s
    DbGuardFailures.unknown_db!(DbGuardConnection.connection_summary) if db_name.empty?

    downcased = db_name.downcase
    if downcased.include?("production") || downcased.include?("development")
      DbGuardFailures.suspect_db_name!(db_name, DbGuardConnection.connection_summary)
    end

    DbGuardFailures.non_test_db!(db_name, DbGuardConnection.connection_summary) unless safe_test_db_name?(db_name)
  end
  private_class_method :ensure_safe_test_database!

  def self.safe_test_db_name?(db_name)
    return true if db_name.end_with?("_test")
    return true if File.basename(db_name).downcase.end_with?("_test.sqlite3")

    adapter = DbGuardConnection.adapter_name
    return false unless adapter.casecmp("sqlite3").zero?

    File.basename(db_name).match?(/\Atest(\.|_).*\.sqlite3\z/i) || File.basename(db_name).casecmp("test.sqlite3").zero?
  rescue StandardError
    false
  end
  private_class_method :safe_test_db_name?
end
