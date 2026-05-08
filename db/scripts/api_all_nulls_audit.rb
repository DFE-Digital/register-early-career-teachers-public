# Audit serialized API output for every `null` value, including fields the
# swagger schema flags as `nullable: true`. Schema violations are called out
# separately. Run via:
#
#   bundle exec rails runner db/scripts/api_all_nulls_audit.rb
#
Dir[Rails.root.join("spec/swagger_schemas/**/*.rb")].sort.each { |f| require f }

# Walks the API response alongside its swagger schema, returning
# `[all_null_paths, violation_paths]` for every JSON `nil` whose field is
# defined in the schema. A path is a violation when its schema does not
# declare `nullable: true`.
class NullFieldAuditor
  # constants defined in the project's swagger schema files under spec/swagger_schemas/
  SWAGGER_SCHEMAS = {
    "IDAttribute" => ID_ATTRIBUTE,
    "Participant" => PARTICIPANT,
    "ParticipantECFEnrolment" => PARTICIPANT_ECF_ENROLMENT,
    "ParticipantIDChange" => PARTICIPANT_ID_CHANGE,
    "Declaration" => DECLARATION,
    "Statement" => STATEMENT,
    "DeliveryPartner" => DELIVERY_PARTNER,
    "Partnership" => PARTNERSHIP,
    "School" => SCHOOL,
    "ParticipantTransfer" => PARTICIPANT_TRANSFER,
    "ParticipantTransfersTransfer" => PARTICIPANT_TRANSFERS_TRANSFER,
    "UnfundedMentor" => UNFUNDED_MENTOR,
  }.freeze

  def nulls(api_json_response, schema_name)
    all_paths = []
    violation_paths = []
    audit(api_json_response, SWAGGER_SCHEMAS.fetch(schema_name), nil, all_paths, violation_paths)
    [all_paths, violation_paths]
  end

private

  def audit(api_json_response, schema, path, all_paths, violation_paths)
    schema = resolve(schema)

    if api_json_response.nil?
      if schema
        all_paths << path
        violation_paths << path unless schema[:nullable]
      end
      return
    end

    return unless schema

    case api_json_response
    when Hash
      properties = schema[:properties] || {}
      api_json_response.each do |key, child|
        property = properties[key.to_sym] || properties[key.to_s]
        audit(child, property, [path, key].compact.join("."), all_paths, violation_paths)
      end
    when Array
      item_schema = schema[:items]
      api_json_response.each do |child|
        audit(child, item_schema, [path, "*"].compact.join("."), all_paths, violation_paths)
      end
    end
  end

  def resolve(schema)
    return nil if schema.nil?

    ref = schema.is_a?(Hash) && schema[:"$ref"]
    return resolve(SWAGGER_SCHEMAS.fetch(ref.split("/").last)) if ref

    schema
  end
end

URL_LIMIT = 5

auditor = NullFieldAuditor.new
findings = {}

# Builds a fetch lambda for the common case: a Query taking only
# `lead_provider_id`, one scope method, and one serializer.
def lp_response(query_class, scope_method, serializer)
  ->(lead_provider) {
    opts = { lead_provider_id: lead_provider.id }
    [[query_class.new(**opts).public_send(scope_method), opts, serializer]]
  }
end

# Each entry's `fetch` returns one or more `[scope, render_opts, serializer]`
# triples. Most endpoints return a single triple; schools fans out per
# contract period.
api_endpoints = [
  { key: :participants,
    schema: "Participant",
    fetch: lp_response(API::Teachers::Query, :teachers, API::TeacherSerializer),
    url: ->(record, _) { "GET /api/v3/participants/#{record.api_id}" } },
  { key: :declarations,
    schema: "Declaration",
    fetch: lp_response(API::Declarations::Query, :declarations, API::DeclarationSerializer),
    url: ->(record, _) { "GET /api/v3/participant-declarations/#{record.api_id}" } },
  { key: :statements,
    schema: "Statement",
    fetch: lp_response(API::Statements::Query, :statements, API::StatementSerializer),
    url: ->(record, _) { "GET /api/v3/statements/#{record.api_id}" } },
  { key: :delivery_partners,
    schema: "DeliveryPartner",
    fetch: lp_response(API::DeliveryPartners::Query, :delivery_partners, API::DeliveryPartnerSerializer),
    url: ->(record, _) { "GET /api/v3/delivery-partners/#{record.api_id}" } },
  { key: :partnerships,
    schema: "Partnership",
    fetch: lp_response(API::SchoolPartnerships::Query, :school_partnerships, API::SchoolPartnershipSerializer),
    url: ->(record, _) { "GET /api/v3/partnerships/#{record.api_id}" } },
  { key: :schools,
    schema: "School",
    fetch: ->(lead_provider) {
      ContractPeriod.pluck(:year).map do |year|
        opts = { lead_provider_id: lead_provider.id, contract_period_year: year }
        [API::Schools::Query.new(**opts).schools, opts, API::SchoolSerializer]
      end
    },
    url: ->(record, opts) { "GET /api/v3/schools/#{record.api_id}?filter[cohort]=#{opts[:contract_period_year]}" } },
  { key: :transfers,
    schema: "ParticipantTransfer",
    fetch: lp_response(API::Teachers::SchoolTransfers::Query, :school_transfers, API::Teachers::SchoolTransferSerializer),
    url: ->(record, _) { "GET /api/v3/participants/#{record.api_id}/transfers" } },
  { key: :unfunded_mentors,
    schema: "UnfundedMentor",
    fetch: lp_response(API::Teachers::UnfundedMentors::Query, :unfunded_mentors, API::Teachers::UnfundedMentorSerializer),
    url: ->(record, _) { "GET /api/v3/unfunded-mentors/#{record.api_id}" } },
]

# Sum of all URLs across each path.
def total_urls(paths_to_urls, only: nil)
  paths_to_urls.sum { |path, urls| only && !only.include?(path) ? 0 : urls.size }
end

$stdout.puts "# Audit of null values in API Responses"
$stdout.puts
$stdout.puts "This audit reports every API field returned as `null`, including fields flagged as `nullable: true` in the Swagger schema. Schema violations (fields not flagged as nullable) are called out in their own section."
$stdout.puts
$stdout.puts "## Audit summary"
$stdout.puts

LeadProvider.alphabetical.each do |lead_provider|
  findings[lead_provider.name] = {}

  detail_lines = []

  api_endpoints.each do |api_endpoint|
    paths_to_urls = Hash.new { |h, k| h[k] = [] }
    violations = Set.new

    api_endpoint[:fetch].call(lead_provider).each do |scope, render_opts, serializer|
      $stdout.puts "#{lead_provider.name} -- #{serializer}"

      scope.find_each(batch_size: 5_000) do |record|
        api_json_response = serializer.render_as_hash(record, **render_opts)
        all_paths, violation_paths = auditor.nulls(api_json_response, api_endpoint[:schema])
        next if all_paths.empty?

        url = api_endpoint[:url].call(record, render_opts)
        all_paths.each { |path| paths_to_urls[path] << url }
        violations.merge(violation_paths)
      end
    end

    findings[lead_provider.name][api_endpoint[:key]] = { paths_to_urls:, violations: }
    next if paths_to_urls.empty?

    total = total_urls(paths_to_urls)
    violation_total = total_urls(paths_to_urls, only: violations)
    suffix = violations.empty? ? "" : " (#{violation_total} schema #{'violation'.pluralize(violation_total)} across #{violations.size} #{'path'.pluralize(violations.size)})"
    detail_lines << "  - #{api_endpoint[:key]}: #{total} nulls across #{paths_to_urls.size} #{'path'.pluralize(paths_to_urls.size)}#{suffix}"
  end

  lp_total = findings[lead_provider.name].values.sum { |entry| total_urls(entry[:paths_to_urls]) }
  lp_violations = findings[lead_provider.name].values.sum { |entry| total_urls(entry[:paths_to_urls], only: entry[:violations]) }
  $stdout.puts "- #{lead_provider.name}: #{lp_total} #{'null'.pluralize(lp_total)} (#{lp_violations} schema #{'violation'.pluralize(lp_violations)})"
  detail_lines.each { |line| $stdout.puts line }
end

$stdout.puts
$stdout.puts "## Schema violations"
$stdout.puts
findings.each do |lead_provider_name, endpoint_findings|
  next if endpoint_findings.values.all? { |entry| entry[:violations].empty? }

  $stdout.puts "### #{lead_provider_name}"
  $stdout.puts
  endpoint_findings.each do |endpoint, entry|
    entry[:paths_to_urls].each do |path, urls|
      next unless entry[:violations].include?(path)

      $stdout.puts "- `#{endpoint}` — `#{path}` (#{urls.size}):"
      urls.first(URL_LIMIT).each { |url| $stdout.puts "  - `#{url}`" }
      $stdout.puts "  - …and #{urls.size - URL_LIMIT} more" if urls.size > URL_LIMIT
    end
  end
  $stdout.puts
end

$stdout.puts "## All nulls by Lead Provider"
$stdout.puts
findings.each do |lead_provider_name, endpoint_findings|
  next if endpoint_findings.values.all? { |entry| entry[:paths_to_urls].empty? }

  $stdout.puts "### #{lead_provider_name}"
  $stdout.puts
  endpoint_findings.each do |endpoint, entry|
    entry[:paths_to_urls].each do |path, urls|
      $stdout.puts "- `#{endpoint}` — `#{path}` (#{urls.size})"
    end
  end
  $stdout.puts
end

$stdout.puts "## Combined totals across lead providers"
$stdout.puts
totals = Hash.new { |h, k| h[k] = Hash.new(0) }
findings.each_value do |endpoint_findings|
  endpoint_findings.each do |endpoint, entry|
    entry[:paths_to_urls].each { |path, urls| totals[endpoint][path] += urls.size }
  end
end
$stdout.puts "```ruby"
totals.each do |endpoint, paths|
  $stdout.puts "#{endpoint.inspect} => #{paths.inspect}"
end
$stdout.puts "```"
