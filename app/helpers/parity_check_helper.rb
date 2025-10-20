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
      mode.new(value: :sequential, name: "Sequential", description: "Send requests one at a time for accurate performance benchmarking.")
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

  def status_code_tag(status_code)
    colour = case status_code
    when 0...300
      "green"
    when 300...400
      "yellow"
    else
      "red"
    end

    govuk_tag(text: status_code, colour:)
  end

  def comparison_emoji(matching)
    matching ? "✅" : "❌"
  end

  def performance_gain(ratio)
    return if ratio.nil?

    formatted_ratio = ratio.abs.to_s.chomp(".0")

    return "⚖️ equal" if ratio == 1
    return "🚀 #{formatted_ratio}x faster" if ratio.positive?

    "🐌 #{formatted_ratio}x slower"
  end

  def id_count_in_words(ids)
    %(#{number_with_delimiter(ids.count)} #{"ID".pluralize(ids.count)})
  end

  def comparison_in_words(matching)
    if matching
      "the same"
    else
      "different"
    end
  end

  def sanitize_diff(html)
    sanitize html, tags: %w[div ul li strong del ins span br], attributes: %w[class]
  end

  def render_filterable_key_hash(hash, key_path: [], &block)
    govuk_list(
      hash.map do |key, nested_hash|
        new_key_path = key_path + [key]
        nested_keys_exist = nested_hash.is_a?(Hash) && nested_hash.any?
        nested_list = render_filterable_key_hash(nested_hash, key_path: new_key_path, &block) if nested_keys_exist

        safe_join([
          yield(new_key_path),
          nested_list
        ])
      end
    )
  end
end
