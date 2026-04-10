Sidekiq.configure_server do |config|
  config.redis = if Rails.env.test?
                   { url: "redis://localhost:6379", connection_pool: nil }
                 else
                   { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1") }
                 end
end

Sidekiq.configure_client do |config|
  config.redis = if Rails.env.test?
                   # In test mode, we don't want Sidekiq to actually try connecting to Redis
                   { url: "redis://localhost:6379", connection_pool: nil }
                 else
                   { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1") }
                 end
end
