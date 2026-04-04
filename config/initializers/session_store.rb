Rails.application.config.session_store(
  :redis_session_store,
  serializer: :json,
  redis: {
    expire_after: ENV.fetch("MAX_SESSION_IDLE_TIME", 7200.seconds).to_i,
    key_prefix: "_ecf2_session:",
    url: ENV.fetch("REDIS_CACHE_URL")
  }
)
