class Migration::CachePerformanceTableComponent < Migration::BaseComponent
  attr_reader :combined_stats

  def initialize(combined_stats:)
    @combined_stats = combined_stats
  end

  def all_cache_types
    (combined_stats[:cache_hits].keys + combined_stats[:cache_misses].keys + combined_stats[:cache_loads].keys).uniq.sort
  end

  def cache_stats_for(cache_type)
    {
      hits: combined_stats[:cache_hits][cache_type] || 0,
      misses: combined_stats[:cache_misses][cache_type] || 0,
      loads: combined_stats[:cache_loads][cache_type] || 0
    }
  end

  def cache_total_requests_tag(hits, misses)
    total = hits + misses
    return govuk_tag(text: "0", colour: "grey") if total.zero?

    govuk_tag(text: number_with_delimiter(total), colour: "blue")
  end

  def cache_hit_rate_tag(hits, misses)
    total = hits + misses
    return govuk_tag(text: "No data", colour: "grey") if total.zero?

    hit_rate = calculate_hit_rate(hits, misses)
    govuk_tag(text: "#{hit_rate}%", colour: hit_rate_colour(hit_rate))
  end
end
