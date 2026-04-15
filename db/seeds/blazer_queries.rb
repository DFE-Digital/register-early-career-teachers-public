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
    name: "Jobs",
    statement: "SELECT * FROM solid_queue_jobs;",
    description: "SolidQueue activity",
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
    statement: "SELECT id AS teacher_id, trs_not_found FROM teachers WHERE trs_not_found=true",
    description: "TRS syncing has flagged missing records"
  },
  {
    name: "TRS deactivated",
    statement: "SELECT id AS teacher_id, trs_deactivated FROM teachers WHERE trs_deactivated=true",
    description: "TRS syncing has flagged deactivated records"
  }
].each do |query|
  create_query(creator: user_manager, **query)
end
