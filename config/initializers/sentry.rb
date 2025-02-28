if Rails.application.config.enable_sentry
  Sentry.init do |config|
    config.dsn = Rails.application.config.sentry_dsn
    config.breadcrumbs_logger = %i[active_support_logger http_logger]
    config.release = ENV["COMMIT_SHA"]
    config.environment = ENV["ENVIRONMENT_NAME"]

    config.enable_tracing = true
    config.traces_sample_rate = 0.1
    config.profiles_sample_rate = 0.1
  end
end
