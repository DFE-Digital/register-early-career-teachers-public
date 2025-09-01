class Migration::DataMigrationPerformanceTableComponent < Migration::BaseComponent
  attr_reader :data_migrations

  def initialize(data_migrations:)
    @data_migrations = data_migrations
  end

  def migration_stats(data_migration)
    stats = data_migration.cache_stats.with_indifferent_access

    overall_hit_rate = stats.dig(:hit_rates, :overall) || 0
    total_hits = stats[:total_hits] || 0
    total_misses = stats[:total_misses] || 0
    caches_hit = caches_hit(stats)
    caches_missed = caches_missed(stats)

    {
      total_hits:,
      total_misses:,
      hit_rate: overall_hit_rate,
      caches_hit:,
      caches_missed:,
      hit_rate_colour: hit_rate_colour(overall_hit_rate)
    }
  end

private

  def caches_hit(stats)
    (stats["cache_hits"] || {}).keys.uniq.sort.map(&:humanize).join(', ')
  end

  def caches_missed(stats)
    (stats["cache_misses"] || {}).keys.uniq.sort.map(&:humanize).join(', ')
  end
end
