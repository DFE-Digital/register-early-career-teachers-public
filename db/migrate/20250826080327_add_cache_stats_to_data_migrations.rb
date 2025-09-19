class AddCacheStatsToDataMigrations < ActiveRecord::Migration[8.0]
  def change
    add_column :data_migrations, :cache_stats, :json
  end
end
