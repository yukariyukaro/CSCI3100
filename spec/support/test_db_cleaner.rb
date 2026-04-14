module TestDbCleaner
  def self.clean!
    return unless enabled?

    conn, tables = connection_and_tables
    conn.disable_referential_integrity { postgres?(conn) ? truncate_all!(conn, tables) : delete_all!(conn, tables) }
  end

  def self.enabled?
    defined?(Rails) && Rails.env.test? && defined?(ActiveRecord::Base)
  end
  private_class_method :enabled?

  def self.connection_and_tables
    conn = ActiveRecord::Base.connection
    [conn, conn.data_sources - %w[schema_migrations ar_internal_metadata]]
  end
  private_class_method :connection_and_tables

  def self.postgres?(conn)
    conn.adapter_name == "PostgreSQL"
  end
  private_class_method :postgres?

  def self.truncate_all!(conn, tables)
    tables.each do |table|
      conn.execute("TRUNCATE TABLE #{conn.quote_table_name(table)} RESTART IDENTITY CASCADE")
    end
  end
  private_class_method :truncate_all!

  def self.delete_all!(conn, tables)
    tables.each do |table|
      conn.execute("DELETE FROM #{conn.quote_table_name(table)}")
    end
  end
  private_class_method :delete_all!
end
