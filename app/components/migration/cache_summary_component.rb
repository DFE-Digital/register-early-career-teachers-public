class Migration::CacheSummaryComponent < Migration::BaseComponent
  attr_reader :combined_stats

  def initialize(combined_stats:)
    @combined_stats = combined_stats
  end

  def total_hits
    combined_stats[:cache_hits].values.sum
  end

  def total_misses
    combined_stats[:cache_misses].values.sum
  end

  def overall_hit_rate
    calculate_hit_rate(total_hits, total_misses)
  end
end
