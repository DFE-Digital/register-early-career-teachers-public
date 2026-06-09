namespace :blazer do
  desc "Create or update the Blazer SQL queries used for RECT email comms to schools (idempotent)"
  task sync_school_comms_queries: :environment do
    require Rails.root.join("db/seeds/blazer_queries/school_comms")

    logger = Logger.new($stdout)
    logger.info("Syncing school comms Blazer queries...")
    queries = BlazerQueries::SchoolComms.sync!
    logger.info("Synced #{queries.size} school comms Blazer queries: #{queries.map(&:name).join(', ')}")
  end
end
