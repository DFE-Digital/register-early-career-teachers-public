def run_commands_in_database(database)
  ActiveRecord::Base.establish_connection(database.to_sym)
  yield
  ActiveRecord::Base.establish_connection(Rails.env.to_sym)
end

def create_extension
  Rails.logger.info("Adding unaccent extension")
  command = %(create extension if not exists unaccent;)

  ActiveRecord::Base.connection.execute(command)
end

def configuration_already_exists?
  query = %(select cfgname from pg_ts_config where cfgname = 'unaccented';)

  ActiveRecord::Base.connection.execute(query).num_tuples == 1
end

def add_configuration
  return if configuration_already_exists?

  Rails.logger.info("Adding full text search configuration")

  command = <<~SQL
    create text search configuration unaccented ( copy = simple );

    alter text search configuration unaccented
      alter mapping for hword, hword_part, word
      with unaccent, simple;
  SQL

  ActiveRecord::Base.connection.execute(command)
end

namespace :db do
  desc 'Add search config'
  task setup_search_configuration: :environment do
    create_extension
    add_configuration

    # NOTE: when we run this in the development env Rails automatically
    #       creates the test database too, but not via `db:create` so
    #       we need to ensure the text search config is applied there too
    if Rails.env.development?
      Rails.logger.info("Adding full text search unaccented config to test env")

      run_commands_in_database(:test) do
        create_extension
        add_configuration
      end
    end
  end
end

# enhance before running the task
Rake::Task['db:schema:load'].enhance(['db:setup_search_configuration'])
Rake::Task['db:prepare'].enhance(['db:setup_search_configuration'])
Rake::Task['db:test:prepare'].enhance(['db:setup_search_configuration'])
# enhance after running the task
Rake::Task['db:create'].enhance { Rake::Task['db:setup_search_configuration'].execute }
