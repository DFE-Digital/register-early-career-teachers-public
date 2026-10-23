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
    description: "All users",
    statement: <<~SQL,
      SELECT *
      FROM users
    SQL
  },
  {
    name: "Events",
    description: "Event timeline",
    statement: <<~SQL,
      SELECT author_name, event_type, heading, body, created_at
      FROM events
      order by created_at desc
    SQL
  },
  {
    name: "Jobs",
    description: "SolidQueue activity",
    statement: <<~SQL,
      SELECT *
      FROM solid_queue_jobs
    SQL
  },
  {
    name: "Schools",
    description: "All schools",
    statement: <<~SQL,
      SELECT urn::text
      FROM schools
    SQL
  },
  {
    name: "DfE Sign-In Organisations",
    description: "DfE authentication responses",
    statement: <<~SQL,
      SELECT
        dsi.id,
        dsi.uuid,
        abp.id AS appropriate_body_id,
        abp.id AS appropriate_body_period,
        dsi.urn::text,
        abp.body_type,
        dsi.category,
        dsi.organisation_type
      FROM appropriate_body_periods abp
      JOIN dfe_sign_in_organisations dsi ON dsi.uuid = abp.dfe_sign_in_organisation_id
      WHERE abp.dfe_sign_in_organisation_id IS NOT NULL
      ORDER BY abp.body_type ASC
    SQL
  },
  {
    name: "Regions",
    description: "Teaching school hub regions",
    statement: <<~SQL,
      SELECT id AS region_id
      FROM regions
    SQL
  },
  {
    name: "Region Awards",
    description: "TSH AB regional awards",
    statement: <<~SQL,
      SELECT
        ra.region_id,
        ra.appropriate_body_period_id AS appropriate_body_id,
        s.urn::text
      FROM region_awards AS ra
      JOIN schools AS s ON ra.school_id=s.id
    SQL
  },
  {
    name: "Teaching School Hubs",
    description: "Regional appropriate bodies (2021 onwards)",
    statement: <<~SQL,
      SELECT
        tsh.id AS teaching_school_hub_id,
        s.urn::text,
        abp.id AS appropriate_body_id,
        abp.id AS appropriate_body_period
      FROM appropriate_body_periods AS abp
      JOIN schools AS s ON abp.school_id=s.id
      JOIN teaching_school_hubs AS tsh ON abp.teaching_school_hub_id=tsh.id
      WHERE abp.body_type='teaching_school_hub'
    SQL
  },
  {
    name: "Teaching Schools",
    description: "Former appropriate bodies (1999 to 2021)",
    statement: <<~SQL,
      SELECT
        s.urn::text,
        abp.id AS appropriate_body_id,
        abp.id AS appropriate_body_period
      FROM appropriate_body_periods AS abp
      JOIN schools AS s ON abp.school_id=s.id
      WHERE abp.body_type='teaching_school'
    SQL
  },
  {
    name: "National Bodies",
    description: "National appropriate bodies (2011 onwards)",
    statement: <<~SQL,
      SELECT
        nb.id AS national_body_id,
        abp.id AS appropriate_body_id,
        abp.id AS appropriate_body_period
      FROM appropriate_body_periods AS abp
      JOIN national_bodies AS nb ON abp.national_body_id=nb.id
      WHERE abp.body_type='national'
    SQL
  },
  {
    name: "Local Authorities",
    description: "Former appropriate bodies (2012 to 2023)",
    statement: <<~SQL,
      SELECT
        la.id AS local_authority_id,
        abp.id AS appropriate_body_id,
        abp.id AS appropriate_body_period
      FROM appropriate_body_periods AS abp
      JOIN local_authorities AS la ON abp.local_authority_id=la.id
      WHERE abp.body_type='local_authority'
    SQL
  },
  {
    name: "Appropriate bodies",
    description: "Time bound role for TSs, TSHs, NBs and LAs",
    statement: <<~SQL,
      SELECT
        body_type,
        id AS appropriate_body_id,
        id AS appropriate_body_period,
        dfe_sign_in_organisation_id
      FROM appropriate_body_periods
      ORDER BY body_type, id, dfe_sign_in_organisation_id
    SQL
  },
  {
    name: "TRS name changes",
    description: "TRS syncing has updated our teacher records",
    statement: <<~SQL,
      SELECT teacher_id, heading
      FROM events
      WHERE event_type='teacher_name_updated_by_trs'
    SQL
  },
  {
    name: "TRS not found",
    description: "TRS syncing has flagged missing records",
    statement: <<~SQL,
      SELECT id AS teacher_id, trs_data_last_refreshed_at
      FROM teachers
      WHERE trs_response='not_found'
    SQL
  },
  {
    name: "TRS deactivated",
    description: "TRS syncing has flagged deactivated records",
    statement: <<~SQL,
      SELECT id AS teacher_id, trs_data_last_refreshed_at
      FROM teachers
      WHERE trs_response='gone'
    SQL
  },
  {
    name: "TRS permanent redirects",
    description: "TRS syncing has flagged records merged into another TRN",
    statement: <<~SQL,
      SELECT id AS teacher_id, trn, trs_redirected_to, trs_data_last_refreshed_at
      FROM teachers
      WHERE trs_response='permanent_redirect'
    SQL
  },
  {
    name: "Framework agreement bands",
    description: "",
    statement: <<~SQL,
      SELECT *
      FROM framework_agreement_bands
      ORDER BY framework_agreement_id, allocation_order
    SQL
  }
].each do |query|
  create_query(creator: user_manager, **query)
end

require Rails.root.join("db/seeds/blazer_queries/school_comms")
BlazerQueries::SchoolComms.sync!

require Rails.root.join("db/seeds/blazer_queries/post_closure_school_links")
BlazerQueries::PostClosureSchoolLinks.sync!
