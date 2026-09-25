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
    statement: "SELECT * FROM users",
    description: "All users",
  },
  {
    name: "Events",
    statement: "SELECT author_name, event_type, heading, body, created_at FROM events order by created_at desc",
    description: "Event timeline"
  },
  {
    name: "Jobs",
    statement: "SELECT * FROM solid_queue_jobs",
    description: "SolidQueue activity",
  },
  {
    name: "Schools",
    statement: "SELECT urn::text FROM schools",
    description: "All schools",
  },
  {
    name: "DfE Sign-In Organisations",
    statement: "SELECT * FROM dfe_sign_in_organisations",
    description: "DfE authentication responses",
  },
  {
    name: "Regions",
    statement: "SELECT id, code, districts FROM regions",
    description: "Teaching school hub regions",
  },
  {
    name: "Teaching School Hubs",
    statement: "SELECT id, name FROM teaching_school_hubs",
    description: "Regional appropriate bodies",
  },
  {
    name: "National Bodies",
    statement: "SELECT id, name FROM national_bodies",
    description: "National appropriate bodies",
  },
  {
    name: "Local Authorities",
    statement: "SELECT id, name FROM local_authorities",
    description: "Former appropriate bodies",
  },
  {
    name: "Appropriate bodies",
    statement: "SELECT id AS appropriate_body_id, id AS appropriate_body_period FROM appropriate_body_periods",
    description: "Time bound role for TSs, TSHs, NBs and LAs",
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
    name: "Framework agreement bands",
    statement: "SELECT * FROM framework_agreement_bands ORDER BY framework_agreement_id, allocation_order",
    description: ""
  }
].each do |query|
  create_query(creator: user_manager, **query)
end

require Rails.root.join("db/seeds/blazer_queries/school_comms")
BlazerQueries::SchoolComms.sync!

require Rails.root.join("db/seeds/blazer_queries/post_closure_school_links")
BlazerQueries::PostClosureSchoolLinks.sync!
