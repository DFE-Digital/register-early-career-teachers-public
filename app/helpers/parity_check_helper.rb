module ParityCheckHelper
  def grouped_endpoints(endpoints)
    endpoints.group_by(&:group_name).sort.to_h
  end

  def grouped_requests(requests)
    requests.group_by { it.endpoint.group_name }.sort.to_h
  end

  def run_mode_options
    mode = Struct.new(:value, :name, :description, keyword_init: true)

    [
      mode.new(value: :concurrent, name: "Concurrent", description: "Send requests in parallel for a faster run."),
      mode.new(value: :sequential, name: "Sequential", description: "Send requests one at a time for accurate performance benchmarking."),
    ]
  end

  def formatted_endpoint_group_name(group_name)
    group_name.to_s.tr("-", " ").humanize
  end

  def formatted_endpoint_group_names(run)
    formatted_group_names = run.request_group_names.map(&method(:formatted_endpoint_group_name))
    govuk_list(formatted_group_names)
  end

  def match_rate_tag(match_rate)
    colour = case match_rate
             when 0..49
               "red"
             when 50..74
               "orange"
             when 75..99
               "yellow"
             else
               "green"
             end

    govuk_tag(text: "#{match_rate}%", colour:)
  end

  def performance_gain(ratio)
    return if ratio.nil?

    return "⚖️ equal" if ratio == 1
    return "🚀 #{ratio}x faster" if ratio > 1

    "🐌 #{ratio}x slower"
  end
end
