# Blazer queries (/admin/blazer) for local, review and staging apps.
#
# Handy for:
# 1. repopulating useful queries
# 2. live demoing a local WIP
# 3. product review of backend data
# 4. saving queries in version control
#
user_manager = User.find_by(name: "Daphne Blake")

def create_query(creator:, name:, statement:, description:)
  Blazer::Query.create(creator:, name:, description:, statement:, data_source: :main, status: :active)
end

[
  {
    name: "Users",
    statement: "SELECT * FROM users;",
    description: nil,
  },
  {
    name: "Events",
    statement: "SELECT author_name, event_type, heading, body, created_at FROM events order by created_at desc",
    description: "Event timeline"
  },
  {
    name: "Jobs",
    statement: "SELECT * FROM solid_queue_jobs;",
    description: "SolidQueue activity",
  },
  {
    name: "Schools",
    statement: "SELECT urn::text FROM schools",
    description: "all schools",
  },
  {
    name: "Appropriate bodies",
    statement: "SELECT * FROM appropriate_bodies;",
    description: "new data model migrating from appropriate_body_periods",
  },
  {
    name: "Legacy appropriate bodies",
    statement: "SELECT * FROM legacy_appropriate_bodies;",
    description: "new data model extracted from appropriate_body_periods",
  },
  {
    name: "DfE Sign-In Organisations",
    statement: "SELECT * FROM dfe_sign_in_organisations;",
    description: "new data model persisted during migration",
  },
  {
    name: "Regions",
    statement: "SELECT * FROM regions;",
    description: "new data model",
  },
  {
    name: "Appropriate body periods",
    statement: "SELECT * FROM appropriate_body_periods;",
    description: "old data model decommisioning and moving fields to other tables",
  },
  {
    name: "TRS name changes",
    statement: "SELECT teacher_id, heading FROM events WHERE event_type='teacher_name_updated_by_trs'",
    description: "TRS syncing has updated our teacher records"
  },
  {
    name: "TRS not found",
    statement: "SELECT id AS teacher_id, trs_data_last_refreshed_at FROM teachers WHERE trs_response='not_found'",
    description: "TRS syncing has flagged missing records"
  },
  {
    name: "TRS deactivated",
    statement: "SELECT id AS teacher_id, trs_data_last_refreshed_at FROM teachers WHERE trs_response='gone'",
    description: "TRS syncing has flagged deactivated records"
  },
  {
    name: "TRS permanent redirects",
    statement: "SELECT id AS teacher_id, trn, trs_redirected_to, trs_data_last_refreshed_at FROM teachers WHERE trs_response='permanent_redirect'",
    description: "TRS syncing has flagged records merged into another TRN"
  },
  {
    name: "Active lead provider bands",
    statement: "SELECT * FROM active_lead_provider_bands ORDER BY active_lead_provider_id, allocation_order",
    description: "new data model"
  },
  {
    name: "Invalid teachers",
    description: "Fails model validations",
    statement: <<~SQL.strip
      SELECT record_id AS teacher_id,
             error_messages,
             created_at
      FROM invalid_records
      WHERE table_name = 'teachers'
      ORDER BY teacher_id
    SQL
  },
  {
    name: "Invalid induction periods",
    description: "Fails model validations",
    statement: <<~SQL.strip
      SELECT t.id AS teacher_id,
            record_id AS induction_period_id,
            error_messages,
            ir.created_at
      FROM invalid_records ir
      JOIN induction_periods ip ON ip.id = ir.record_id
      JOIN teachers t ON t.id = ip.teacher_id
      WHERE table_name = 'induction_periods'
      ORDER BY teacher_id
    SQL
  }
].each do |query|
  create_query(creator: user_manager, **query)
end

require Rails.root.join("db/seeds/blazer_queries/school_comms")
BlazerQueries::SchoolComms.sync!

require Rails.root.join("db/seeds/blazer_queries/post_closure_school_links")
BlazerQueries::PostClosureSchoolLinks.sync!
