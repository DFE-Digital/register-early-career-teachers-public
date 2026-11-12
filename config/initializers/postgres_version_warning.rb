module PostgresVersionWarning
  MINIMUM_DATABASE_VERSION = 180_000
  WARNING_MESSAGE = "PostgreSQL v18 or newer is recommended in development and test. " \
    "Detected database_version=%<database_version>d."

module_function

  def warn_if_outdated(logger: Rails.logger, environment: Rails.env, connection_pool: ActiveRecord::Base.connection_pool)
    return unless environment.local?

    database_version = connection_pool.with_connection(&:database_version)
    return if database_version >= MINIMUM_DATABASE_VERSION

    logger.warn(sprintf(WARNING_MESSAGE, database_version:))
  rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::NoDatabaseError => e
    logger.warn("Unable to determine PostgreSQL database version during boot: #{e.class}: #{e.message}")
  end
end

Rails.application.config.after_initialize do
  PostgresVersionWarning.warn_if_outdated
end
