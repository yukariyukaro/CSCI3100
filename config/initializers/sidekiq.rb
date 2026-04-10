Sidekiq.configure_server do |config|
  if Rails.env.test?
    config.redis = { url: 'redis://localhost:6379' }
  else
    config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1') }
  end
end

Sidekiq.configure_client do |config|
  if Rails.env.test?
    config.redis = { url: 'redis://localhost:6379' }
  else
    config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1') }
  end
end