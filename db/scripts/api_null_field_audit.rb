# Audit serialized API output for `null` values that the swagger schema says
# should never be `null`. One-off check for issue #3902. Run via:
#
#   bundle exec rails runner db/scripts/api_null_field_audit.rb
#
Dir[Rails.root.join("spec/swagger_schemas/**/*.rb")].sort.each { |f| require f }

# Walks the API response alongside its swagger schema,
# returns a path where the JSON is `nil` and the schema does not declare `nullable: true`.
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

  def unexpected_nulls(api_json_response, schema_name)
    unexpected_null_paths = []
    audit(api_json_response, SWAGGER_SCHEMAS.fetch(schema_name), nil, unexpected_null_paths)
    unexpected_null_paths
  end

private

  def audit(api_json_response, schema, path, unexpected_null_paths)
    schema = resolve(schema)

    if api_json_response.nil?
      unexpected_null_paths << path if schema && !schema[:nullable]
      return
    end

    return unless schema

    case api_json_response
    when Hash
      properties = schema[:properties] || {}
      api_json_response.each do |key, child|
        property = properties[key.to_sym] || properties[key.to_s]
        audit(child, property, [path, key].compact.join("."), unexpected_null_paths)
      end
    when Array
      item_schema = schema[:items]
      api_json_response.each do |child|
        audit(child, item_schema, [path, "*"].compact.join("."), unexpected_null_paths)
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

$stdout.puts "# Audit of unexpected null values in API Responses"
$stdout.puts
$stdout.puts "This audit highlights where API responses contain `null` values in violation of the Swagger API schema definition."
$stdout.puts
$stdout.puts "## Audit summary"
$stdout.puts

LeadProvider.alphabetical.each do |lead_provider|
  findings[lead_provider.name] = {}

  detail_lines = []

  api_endpoints.each do |api_endpoint|
    paths_to_urls = Hash.new { |h, k| h[k] = [] }

    api_endpoint[:fetch].call(lead_provider).each do |scope, render_opts, serializer|
      $stdout.puts "#{lead_provider.name} -- #{serializer}"

      scope.find_each(batch_size: 5_000) do |record|
        api_json_response = serializer.render_as_hash(record, **render_opts)
        violations = auditor.unexpected_nulls(api_json_response, api_endpoint[:schema])
        next if violations.empty?

        url = api_endpoint[:url].call(record, render_opts)
        violations.each { |path| paths_to_urls[path] << url }
      end
    end

    findings[lead_provider.name][api_endpoint[:key]] = paths_to_urls
    next if paths_to_urls.empty?

    total = paths_to_urls.values.sum(&:size)
    detail_lines << "  - #{api_endpoint[:key]}: #{total} unexpected nulls across #{paths_to_urls.size} #{'path'.pluralize(paths_to_urls.size)}"
  end

  lp_total = findings[lead_provider.name].values.sum { |paths| paths.values.sum(&:size) }
  $stdout.puts "- #{lead_provider.name}: #{lp_total} unexpected #{'null'.pluralize(lp_total)}"
  detail_lines.each { |line| $stdout.puts line }
end

$stdout.puts
$stdout.puts "## Unexpected nulls by Lead Provider"
$stdout.puts
findings.each do |lead_provider_name, endpoint_findings|
  next if endpoint_findings.values.all?(&:empty?)

  $stdout.puts "### #{lead_provider_name}"
  $stdout.puts
  endpoint_findings.each do |endpoint, paths_to_urls|
    next if paths_to_urls.empty?

    paths_to_urls.each do |path, urls|
      $stdout.puts "- `#{endpoint}` — `#{path}` (#{urls.size}):"
      urls.each { |url| $stdout.puts "  - `#{url}`" }
    end
  end
  $stdout.puts
end

$stdout.puts "## Combined totals across lead providers"
$stdout.puts
totals = Hash.new { |h, k| h[k] = Hash.new(0) }
findings.each_value do |endpoint_findings|
  endpoint_findings.each do |endpoint, paths_to_urls|
    paths_to_urls.each { |path, urls| totals[endpoint][path] += urls.size }
  end
end
$stdout.puts "```ruby"
totals.each do |endpoint, paths|
  $stdout.puts "#{endpoint.inspect} => #{paths.inspect}"
end
$stdout.puts "```"
