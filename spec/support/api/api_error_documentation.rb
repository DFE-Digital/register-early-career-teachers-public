class APIErrorDocumentation
  class UndocumentedError < StandardError; end

  COLUMNS = %i[attribute message cause].freeze

  def initialize
    @errors = Set.new
  end

  def add_error(example:, service:, attribute:, message:)
    errors << { service:, attribute:, message: normalize_message(message), cause: infer_cause(example) }
  end

  def write(path)
    return if path.blank? || errors.empty?

    File.write(path, markdown)
  end

  def verify_completeness!
    errors.group_by { it[:service] }.each do |service, service_errors|
      expected = extract_all_error_attributes(service)
      documented = service_errors.map { it[:attribute] }.uniq
      missing = expected - documented

      raise UndocumentedError, "Missing validation error documentation for #{service}: #{missing.join(', ')}" if missing.any?
    end
  end

private

  attr_reader :errors

  def markdown
    [
      "# API errors",
      *errors_by_service.map(&method(:service_section))
    ].join("\n\n")
  end

  def service_section(service, service_errors)
    [
      service_heading(service),
      *table_header,
      *service_errors.map { table_row(it.values_at(*COLUMNS)) }
    ].join("\n")
  end

  def table_header
    [
      table_row(COLUMNS.map { it.to_s.capitalize }),
      table_row(COLUMNS.map { "---" })
    ]
  end

  def table_row(cells)
    "| #{cells.join(' | ')} |"
  end

  def errors_by_service
    errors
      .sort_by { [it[:service].name, *it.values_at(*COLUMNS)] }
      .group_by { it[:service] }
  end

  def service_heading(service)
    "## #{service.name.delete_prefix('API::').split('::').join(' → ')}\n"
  end

  def normalize_message(message)
    date_time_pattern = /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/
    contract_period_year_pattern = /the \d{4} contract period/

    message
      .gsub(date_time_pattern, "<datetime>")
      .gsub(contract_period_year_pattern, "the <contract period year> contract period")
  end

  def infer_cause(example)
    causal_context_prefix_pattern = /\A(?:when|with|without|if|unless)\b/i

    cause = example
      .example_group
      .parent_groups
      .map(&:description)
      .grep(causal_context_prefix_pattern)
      .last

    "#{(cause || 'unspecified').upcase_first}."
  end

  def extract_all_error_attributes(service)
    (
      extract_add_error_attributes(service) +
      extract_validation_rule_attributes(service)
    ).uniq
  end

  def extract_add_error_attributes(service)
    add_error_signature_pattern = /errors\.add\s*(?:\(\s*)?:(\w+)/

    service.ancestors
      .filter_map { it.name && Object.const_source_location(it.name)&.first }
      .select { it.start_with?(Rails.root.to_s) && it.include?("/api/") }
      .flat_map { File.read(it).scan(add_error_signature_pattern).flatten }
      .map(&:to_sym)
  end

  def extract_validation_rule_attributes(service)
    service.validators
      .filter_map { it.attributes if it.respond_to?(:attributes) }
      .flatten
  end
end
