namespace :blazer do
  desc "Create or update the Blazer SQL queries used for RECT email comms to schools (idempotent)"
  task sync_school_comms_queries: :environment do
    require Rails.root.join("db/seeds/blazer_queries/school_comms")

    logger = Logger.new($stdout)
    logger.info("Syncing school comms Blazer queries...")
    queries = BlazerQueries::SchoolComms.sync!
    logger.info("Synced #{queries.size} school comms Blazer queries: #{queries.map(&:name).join(', ')}")
  end

  desc "Create or update the Blazer SQL queries for schools linked to a successor after we closed them (idempotent)"
  task sync_post_closure_school_link_queries: :environment do
    require Rails.root.join("db/seeds/blazer_queries/post_closure_school_links")

    logger = Logger.new($stdout)
    logger.info("Syncing post closure school link Blazer queries...")
    queries = BlazerQueries::PostClosureSchoolLinks.sync!
    logger.info("Synced #{queries.size} post closure school link Blazer queries: #{queries.map(&:name).join(', ')}")
  end
end
