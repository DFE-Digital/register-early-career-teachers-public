module ParityCheckHelper
  def grouped_endpoints(endpoints)
    endpoints.group_by(&:group_name)
  end

  def run_mode_options
    mode = Struct.new(:value, :name, :description, keyword_init: true)

    [
      mode.new(value: :concurrent, name: "Concurrent", description: "Send requests in parallel for a faster run."),
      mode.new(value: :sequential, name: "Sequential", description: "Send requests one at a time for accurate performance benchmarking."),
    ]
  end
end
