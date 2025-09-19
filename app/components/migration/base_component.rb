class Migration::BaseComponent < ApplicationComponent
  def calculate_hit_rate(hits, misses)
    total = hits + misses
    return 0 if total.zero?

    (hits.to_f / total * 100).truncate(2)
  end

  def hit_rate_colour(hit_rate)
    if hit_rate >= 90
      "green"
    elsif hit_rate >= 70
      "yellow"
    else
      "red"
    end
  end
end
