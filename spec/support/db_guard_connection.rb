module DbGuardConnection
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

  def self.adapter_name
    cfg = safe_connection_config
    cfg_value(cfg, :adapter).to_s
  end

  def self.current_db_name
    return unless defined?(ActiveRecord::Base)

    cfg = ActiveRecord::Base.connection_db_config
    cfg&.database
  rescue StandardError
    nil
  end

  def self.safe_connection_config
    return {} unless defined?(ActiveRecord::Base)

    cfg = ActiveRecord::Base.connection_db_config
    raw = cfg&.configuration_hash || {}
    sanitize_connection_config(raw)
  rescue StandardError
    {}
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

  def self.sanitize_connection_config(raw)
    sanitized = raw.dup
    sanitized.delete(:password)
    sanitized.delete("password")
    sanitized.delete(:url)
    sanitized.delete("url")
    sanitized
  end
  private_class_method :sanitize_connection_config
end
