class Migration::BaseComponent < ApplicationComponent
  def success_rate(success, fails)
    total = success + fails
    return 0 if total.zero?

    (success.to_f / total * 100).truncate(2)
  end
  alias_method :calculate_hit_rate, :success_rate

  def rate_colour(rate)
    return "green" if rate >= 90
    return "yellow" if rate >= 70

    "red"
  end
  alias_method :hit_rate_colour, :rate_colour
end
