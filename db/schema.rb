# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_11_07_093813) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "unaccent"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "appropriate_body_type", ["local_authority", "national", "teaching_school_hub"]
  create_enum "batch_status", ["pending", "processing", "processed", "completing", "completed", "failed"]
  create_enum "batch_type", ["action", "claim"]
  create_enum "declaration_types", ["started", "retained-1", "retained-2", "retained-3", "retained-4", "completed", "extended-1", "extended-2", "extended-3"]
  create_enum "deferral_reasons", ["bereavement", "long_term_sickness", "parental_leave", "career_break", "other"]
  create_enum "dfe_role_type", ["admin", "super_admin", "finance"]
  create_enum "event_author_types", ["appropriate_body_user", "school_user", "dfe_staff_user", "system", "lead_provider_api"]
  create_enum "fee_types", ["output", "service"]
  create_enum "funding_eligibility_status", ["eligible_for_fip", "eligible_for_cip", "ineligible"]
  create_enum "gias_school_statuses", ["open", "closed", "proposed_to_close", "proposed_to_open"]
  create_enum "induction_outcomes", ["fail", "pass"]
  create_enum "induction_programme", ["cip", "fip", "diy", "unknown", "pre_september_2021"]
  create_enum "induction_programme_choice", ["not_yet_known", "provider_led", "school_led"]
  create_enum "mentor_became_ineligible_for_funding_reason", ["completed_declaration_received", "completed_during_early_roll_out", "started_not_completed"]
  create_enum "parity_check_request_states", ["pending", "queued", "in_progress", "completed", "failed"]
  create_enum "parity_check_run_modes", ["concurrent", "sequential"]
  create_enum "parity_check_run_states", ["pending", "in_progress", "completed", "failed"]
  create_enum "request_method_types", ["get", "post", "put"]
  create_enum "schedule_identifiers", ["ecf-extended-april", "ecf-extended-january", "ecf-extended-september", "ecf-reduced-april", "ecf-reduced-january", "ecf-reduced-september", "ecf-replacement-april", "ecf-replacement-january", "ecf-replacement-september", "ecf-standard-april", "ecf-standard-january", "ecf-standard-september"]
  create_enum "statement_statuses", ["open", "payable", "paid"]
  create_enum "training_programme", ["provider_led", "school_led"]
  create_enum "withdrawal_reasons", ["left_teaching_profession", "moved_school", "mentor_no_longer_being_mentor", "switched_to_school_led", "other"]
  create_enum "working_pattern", ["part_time", "full_time"]

  create_table "active_lead_providers", force: :cascade do |t|
    t.bigint "lead_provider_id", null: false
    t.bigint "contract_period_year", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_period_year"], name: "index_active_lead_providers_on_contract_period_year"
    t.index ["lead_provider_id", "contract_period_year"], name: "idx_on_lead_provider_id_contract_period_year_e442ca2260", unique: true
    t.index ["lead_provider_id"], name: "index_active_lead_providers_on_lead_provider_id"
  end

  create_table "api_tokens", force: :cascade do |t|
    t.bigint "lead_provider_id"
    t.string "token", null: false
    t.string "description", null: false
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lead_provider_id"], name: "index_api_tokens_on_lead_provider_id"
    t.index ["token"], name: "index_api_tokens_on_token", unique: true
  end

  create_table "appropriate_bodies", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "dfe_sign_in_organisation_id"
    t.uuid "dqt_id"
    t.enum "body_type", default: "teaching_school_hub", enum_type: "appropriate_body_type"
    t.index ["dfe_sign_in_organisation_id"], name: "index_appropriate_bodies_on_dfe_sign_in_organisation_id", unique: true
  end

  create_table "blazer_audits", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "query_id"
    t.text "statement"
    t.string "data_source"
    t.datetime "created_at"
    t.index ["query_id"], name: "index_blazer_audits_on_query_id"
    t.index ["user_id"], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", force: :cascade do |t|
    t.bigint "creator_id"
    t.bigint "query_id"
    t.string "state"
    t.string "schedule"
    t.text "emails"
    t.text "slack_channels"
    t.string "check_type"
    t.text "message"
    t.datetime "last_run_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_checks_on_creator_id"
    t.index ["query_id"], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", force: :cascade do |t|
    t.bigint "dashboard_id"
    t.bigint "query_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dashboard_id"], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index ["query_id"], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_queries", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "name"
    t.text "description"
    t.text "statement"
    t.string "data_source"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_queries_on_creator_id"
  end

  create_table "contract_periods", primary_key: "year", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "started_on"
    t.date "finished_on"
    t.boolean "enabled", default: false
    t.virtual "range", type: :daterange, as: "daterange(started_on, finished_on)", stored: true
    t.index ["year"], name: "index_contract_periods_on_year", unique: true
  end

  create_table "data_migrations", force: :cascade do |t|
    t.string "model", null: false
    t.integer "processed_count", default: 0, null: false
    t.integer "failure_count", default: 0, null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "total_count"
    t.datetime "queued_at"
    t.integer "worker"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "cache_stats"
  end

  create_table "declarations", force: :cascade do |t|
    t.bigint "training_period_id"
    t.string "declaration_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["training_period_id"], name: "index_declarations_on_training_period_id"
  end

  create_table "delivery_partners", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "api_id", default: -> { "gen_random_uuid()" }, null: false
    t.datetime "api_updated_at", default: -> { "CURRENT_TIMESTAMP" }
    t.index ["api_id"], name: "index_delivery_partners_on_api_id", unique: true
    t.index ["name"], name: "index_delivery_partners_on_name", unique: true
  end

  create_table "ect_at_school_periods", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "teacher_id", null: false
    t.date "started_on", null: false
    t.date "finished_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.virtual "range", type: :daterange, as: "daterange(started_on, finished_on)", stored: true
    t.uuid "ecf_start_induction_record_id"
    t.uuid "ecf_end_induction_record_id"
    t.enum "working_pattern", enum_type: "working_pattern"
    t.citext "email"
    t.bigint "school_reported_appropriate_body_id"
    t.index "teacher_id, ((finished_on IS NULL))", name: "index_ect_at_school_periods_on_teacher_id_finished_on_IS_NULL", unique: true, where: "(finished_on IS NULL)"
    t.index ["school_id", "teacher_id", "started_on"], name: "index_ect_at_school_periods_on_school_id_teacher_id_started_on", unique: true
    t.index ["school_id"], name: "index_ect_at_school_periods_on_school_id"
    t.index ["school_reported_appropriate_body_id"], name: "idx_on_school_reported_appropriate_body_id_01f5ffc90a"
    t.index ["teacher_id", "started_on"], name: "index_ect_at_school_periods_on_teacher_id_started_on", unique: true
    t.index ["teacher_id"], name: "index_ect_at_school_periods_on_teacher_id"
  end

  create_table "events", force: :cascade do |t|
    t.text "heading"
    t.text "body"
    t.text "event_type"
    t.datetime "happened_at", default: -> { "CURRENT_TIMESTAMP" }
    t.integer "teacher_id"
    t.integer "appropriate_body_id"
    t.integer "induction_period_id"
    t.integer "induction_extension_id"
    t.integer "school_id"
    t.integer "ect_at_school_period_id"
    t.integer "mentor_at_school_period_id"
    t.integer "training_period_id"
    t.integer "mentorship_period_id"
    t.integer "school_partnership_id"
    t.integer "lead_provider_id"
    t.integer "delivery_partner_id"
    t.integer "user_id"
    t.enum "author_type", null: false, enum_type: "event_author_types"
    t.integer "author_id"
    t.text "author_name"
    t.citext "author_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "metadata"
    t.string "modifications", array: true
    t.bigint "active_lead_provider_id"
    t.bigint "lead_provider_delivery_partnership_id"
    t.bigint "pending_induction_submission_batch_id"
    t.bigint "statement_id"
    t.bigint "statement_adjustment_id"
    t.integer "zendesk_ticket_id"
    t.bigint "schedule_id"
    t.index ["active_lead_provider_id"], name: "index_events_on_active_lead_provider_id"
    t.index ["appropriate_body_id"], name: "index_events_on_appropriate_body_id"
    t.index ["author_email"], name: "index_events_on_author_email"
    t.index ["author_id"], name: "index_events_on_author_id"
    t.index ["delivery_partner_id"], name: "index_events_on_delivery_partner_id"
    t.index ["ect_at_school_period_id"], name: "index_events_on_ect_at_school_period_id"
    t.index ["induction_extension_id"], name: "index_events_on_induction_extension_id"
    t.index ["induction_period_id"], name: "index_events_on_induction_period_id"
    t.index ["lead_provider_delivery_partnership_id"], name: "index_events_on_lead_provider_delivery_partnership_id"
    t.index ["lead_provider_id"], name: "index_events_on_lead_provider_id"
    t.index ["mentor_at_school_period_id"], name: "index_events_on_mentor_at_school_period_id"
    t.index ["mentorship_period_id"], name: "index_events_on_mentorship_period_id"
    t.index ["pending_induction_submission_batch_id"], name: "index_events_on_pending_induction_submission_batch_id"
    t.index ["school_id"], name: "index_events_on_school_id"
    t.index ["school_partnership_id"], name: "index_events_on_school_partnership_id"
    t.index ["statement_adjustment_id"], name: "index_events_on_statement_adjustment_id"
    t.index ["statement_id"], name: "index_events_on_statement_id"
    t.index ["teacher_id"], name: "index_events_on_teacher_id"
    t.index ["training_period_id"], name: "index_events_on_training_period_id"
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "gias_school_links", force: :cascade do |t|
    t.integer "urn", null: false
    t.integer "link_urn", null: false
    t.string "link_type", null: false
    t.date "link_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["urn"], name: "index_gias_school_links_on_urn"
  end

  create_table "gias_schools", primary_key: "urn", force: :cascade do |t|
    t.string "name", null: false
    t.enum "status", default: "open", null: false, enum_type: "gias_school_statuses"
    t.enum "funding_eligibility", null: false, enum_type: "funding_eligibility_status"
    t.string "address_line1"
    t.string "address_line2"
    t.string "address_line3"
    t.string "postcode"
    t.string "primary_contact_email"
    t.string "secondary_contact_email"
    t.date "opened_on"
    t.date "closed_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "administrative_district_name"
    t.integer "local_authority_code", null: false
    t.string "local_authority_name"
    t.integer "establishment_number"
    t.string "phase_name"
    t.boolean "section_41_approved", null: false
    t.string "type_name", null: false
    t.integer "ukprn"
    t.string "website"
    t.boolean "induction_eligibility", null: false
    t.boolean "in_england", null: false
    t.virtual "search", type: :tsvector, as: "to_tsvector('unaccented'::regconfig, ((((COALESCE((name)::text, ''::text) || ' '::text) || COALESCE((postcode)::text, ''::text)) || ' '::text) || COALESCE((urn)::text, ''::text)))", stored: true
    t.index ["name"], name: "index_gias_schools_on_name"
    t.index ["search"], name: "index_gias_schools_on_search", using: :gin
    t.index ["ukprn"], name: "index_gias_schools_on_ukprn", unique: true
  end

  create_table "induction_extensions", force: :cascade do |t|
    t.bigint "teacher_id", null: false
    t.float "number_of_terms", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["teacher_id"], name: "index_induction_extensions_on_teacher_id"
  end

  create_table "induction_periods", force: :cascade do |t|
    t.bigint "appropriate_body_id", null: false
    t.date "started_on", null: false
    t.date "finished_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.enum "induction_programme", null: false, enum_type: "induction_programme"
    t.float "number_of_terms"
    t.virtual "range", type: :daterange, as: "daterange(started_on, finished_on)", stored: true
    t.bigint "teacher_id"
    t.enum "outcome", enum_type: "induction_outcomes"
    t.enum "training_programme", enum_type: "training_programme"
    t.index ["appropriate_body_id"], name: "index_induction_periods_on_appropriate_body_id"
    t.index ["teacher_id"], name: "index_induction_periods_on_teacher_id"
  end

  create_table "lead_provider_delivery_partnerships", force: :cascade do |t|
    t.bigint "active_lead_provider_id", null: false
    t.bigint "delivery_partner_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "ecf_id"
    t.index ["active_lead_provider_id", "delivery_partner_id"], name: "idx_on_active_lead_provider_id_delivery_partner_id_3c66d9e812", unique: true
    t.index ["active_lead_provider_id"], name: "idx_on_active_lead_provider_id_2f96b67fbb"
    t.index ["delivery_partner_id"], name: "idx_on_delivery_partner_id_fcb95e8215"
    t.index ["ecf_id"], name: "index_lead_provider_delivery_partnerships_on_ecf_id", unique: true
  end

  create_table "lead_providers", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "ecf_id"
    t.index ["ecf_id"], name: "index_lead_providers_on_ecf_id", unique: true
    t.index ["name"], name: "index_lead_providers_on_name", unique: true
  end

  create_table "mentor_at_school_periods", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "teacher_id", null: false
    t.date "started_on", null: false
    t.date "finished_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.virtual "range", type: :daterange, as: "daterange(started_on, finished_on)", stored: true
    t.uuid "ecf_start_induction_record_id"
    t.uuid "ecf_end_induction_record_id"
    t.citext "email"
    t.index "school_id, teacher_id, ((finished_on IS NULL))", name: "idx_on_school_id_teacher_id_finished_on_IS_NULL_dd7ee16a28", unique: true, where: "(finished_on IS NULL)"
    t.index ["school_id", "teacher_id", "started_on"], name: "idx_on_school_id_teacher_id_started_on_17d46e7783", unique: true
    t.index ["school_id"], name: "index_mentor_at_school_periods_on_school_id"
    t.index ["teacher_id"], name: "index_mentor_at_school_periods_on_teacher_id"
  end

  create_table "mentorship_periods", force: :cascade do |t|
    t.bigint "ect_at_school_period_id", null: false
    t.bigint "mentor_at_school_period_id", null: false
    t.date "started_on", null: false
    t.date "finished_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.virtual "range", type: :daterange, as: "daterange(started_on, finished_on)", stored: true
    t.uuid "ecf_start_induction_record_id"
    t.uuid "ecf_end_induction_record_id"
    t.index "ect_at_school_period_id, ((finished_on IS NULL))", name: "idx_on_ect_at_school_period_id_finished_on_IS_NULL_afd5cf131d", unique: true, where: "(finished_on IS NULL)"
    t.index ["ect_at_school_period_id", "started_on"], name: "index_mentorship_periods_on_ect_at_school_period_id_started_on", unique: true
    t.index ["ect_at_school_period_id"], name: "index_mentorship_periods_on_ect_at_school_period_id"
    t.index ["mentor_at_school_period_id", "ect_at_school_period_id", "started_on"], name: "idx_on_mentor_at_school_period_id_ect_at_school_per_d69dffeecc", unique: true
    t.index ["mentor_at_school_period_id"], name: "index_mentorship_periods_on_mentor_at_school_period_id"
  end

  create_table "metadata_delivery_partners_lead_providers", force: :cascade do |t|
    t.bigint "delivery_partner_id", null: false
    t.bigint "lead_provider_id", null: false
    t.integer "contract_period_years", default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_partner_id", "lead_provider_id"], name: "idx_on_delivery_partner_id_lead_provider_id_a83df5ed0c", unique: true
    t.index ["delivery_partner_id"], name: "idx_on_delivery_partner_id_d734fa500e"
    t.index ["lead_provider_id"], name: "idx_on_lead_provider_id_b318746369"
  end

  create_table "metadata_schools_contract_periods", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.integer "contract_period_year"
    t.boolean "in_partnership", null: false
    t.enum "induction_programme_choice", null: false, enum_type: "induction_programme_choice"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_period_year"], name: "idx_on_contract_period_year_e703aaa45a"
    t.index ["school_id", "contract_period_year"], name: "idx_on_school_id_contract_period_year_0dae2d65f6", unique: true
    t.index ["school_id"], name: "index_metadata_schools_contract_periods_on_school_id"
  end

  create_table "metadata_schools_lead_providers_contract_periods", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "lead_provider_id", null: false
    t.integer "contract_period_year"
    t.boolean "expression_of_interest_or_school_partnership", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_period_year"], name: "idx_on_contract_period_year_f5913b27f2"
    t.index ["lead_provider_id"], name: "idx_on_lead_provider_id_bb46a39503"
    t.index ["school_id", "lead_provider_id", "contract_period_year"], name: "idx_on_school_id_lead_provider_id_contract_period_y_54fbb99e92", unique: true
    t.index ["school_id"], name: "idx_on_school_id_b772864906"
  end

  create_table "metadata_teachers_lead_providers", force: :cascade do |t|
    t.bigint "teacher_id"
    t.bigint "lead_provider_id"
    t.bigint "latest_ect_training_period_id"
    t.bigint "latest_mentor_training_period_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "api_mentor_id"
    t.integer "latest_ect_contract_period_year"
    t.integer "latest_mentor_contract_period_year"
    t.index ["latest_ect_training_period_id"], name: "idx_on_latest_ect_training_period_id_2d0632b258"
    t.index ["latest_mentor_training_period_id"], name: "idx_on_latest_mentor_training_period_id_862127afaf"
    t.index ["lead_provider_id", "teacher_id"], name: "idx_on_lead_provider_id_teacher_id_74c7a13188", where: "((latest_ect_training_period_id IS NOT NULL) OR (latest_mentor_training_period_id IS NOT NULL))"
    t.index ["lead_provider_id"], name: "index_metadata_teachers_lead_providers_on_lead_provider_id"
    t.index ["teacher_id", "lead_provider_id"], name: "idx_on_teacher_id_lead_provider_id_23bbab847a", unique: true
    t.index ["teacher_id"], name: "index_metadata_teachers_lead_providers_on_teacher_id"
  end

  create_table "migration_failures", force: :cascade do |t|
    t.bigint "data_migration_id", null: false
    t.json "item", null: false
    t.string "failure_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "parent_id"
    t.string "parent_type"
    t.index ["data_migration_id"], name: "index_migration_failures_on_data_migration_id"
    t.index ["parent_id"], name: "index_migration_failures_on_parent_id"
  end

  create_table "milestones", force: :cascade do |t|
    t.bigint "schedule_id"
    t.enum "declaration_type", null: false, enum_type: "declaration_types"
    t.date "start_date", null: false
    t.date "milestone_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["schedule_id", "declaration_type"], name: "index_milestones_on_schedule_id_and_declaration_type", unique: true
    t.index ["schedule_id"], name: "index_milestones_on_schedule_id"
  end

  create_table "parity_check_endpoints", force: :cascade do |t|
    t.string "path", null: false
    t.enum "method", null: false, enum_type: "request_method_types"
    t.jsonb "options", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "parity_check_requests", force: :cascade do |t|
    t.bigint "run_id", null: false
    t.bigint "lead_provider_id", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "endpoint_id"
    t.enum "state", default: "pending", null: false, enum_type: "parity_check_request_states"
    t.index ["endpoint_id"], name: "index_parity_check_requests_on_endpoint_id"
    t.index ["lead_provider_id"], name: "index_parity_check_requests_on_lead_provider_id"
    t.index ["run_id"], name: "index_parity_check_requests_on_run_id"
  end

  create_table "parity_check_responses", force: :cascade do |t|
    t.bigint "request_id", null: false
    t.integer "ecf_status_code", null: false
    t.integer "rect_status_code", null: false
    t.string "ecf_body"
    t.string "rect_body"
    t.integer "ecf_time_ms", null: false
    t.integer "rect_time_ms", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "page"
    t.string "ecf_request_uri"
    t.string "rect_request_uri"
    t.jsonb "request_body"
    t.integer "match_rate", default: 0, null: false
    t.index ["request_id", "page"], name: "index_parity_check_responses_on_request_id_and_page", unique: true
    t.index ["request_id"], name: "index_parity_check_responses_on_request_id"
  end

  create_table "parity_check_runs", force: :cascade do |t|
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.enum "state", default: "pending", null: false, enum_type: "parity_check_run_states"
    t.enum "mode", default: "concurrent", null: false, enum_type: "parity_check_run_modes"
    t.index ["state"], name: "index_parity_check_runs_on_state", unique: true, where: "(state = 'in_progress'::parity_check_run_states)"
  end

  create_table "pending_induction_submission_batches", force: :cascade do |t|
    t.bigint "appropriate_body_id", null: false
    t.enum "batch_type", null: false, enum_type: "batch_type"
    t.enum "batch_status", default: "pending", null: false, enum_type: "batch_status"
    t.string "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "data"
    t.string "file_name"
    t.integer "uploaded_count"
    t.integer "processed_count"
    t.integer "errored_count"
    t.integer "released_count"
    t.integer "failed_count"
    t.integer "passed_count"
    t.integer "claimed_count"
    t.integer "file_size"
    t.string "file_type"
    t.index ["appropriate_body_id"], name: "idx_on_appropriate_body_id_58d86a161e"
  end

  create_table "pending_induction_submissions", force: :cascade do |t|
    t.bigint "appropriate_body_id"
    t.string "establishment_id", limit: 8
    t.string "trn", limit: 7, null: false
    t.string "trs_first_name", limit: 80
    t.string "trs_last_name", limit: 80
    t.date "date_of_birth"
    t.string "trs_induction_status"
    t.enum "induction_programme", enum_type: "induction_programme"
    t.date "started_on"
    t.date "finished_on"
    t.float "number_of_terms"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "confirmed_at"
    t.citext "trs_email_address"
    t.jsonb "trs_alerts"
    t.date "trs_induction_start_date"
    t.string "trs_induction_status_description"
    t.string "trs_qts_status_description"
    t.date "trs_initial_teacher_training_end_date"
    t.string "trs_initial_teacher_training_provider_name"
    t.enum "outcome", enum_type: "induction_outcomes"
    t.date "trs_qts_awarded_on"
    t.datetime "delete_at", precision: nil
    t.bigint "pending_induction_submission_batch_id"
    t.string "error_messages", default: [], array: true
    t.enum "training_programme", enum_type: "training_programme"
    t.boolean "trs_prohibited_from_teaching"
    t.date "trs_induction_completed_date"
    t.date "trs_date_of_birth"
    t.index ["appropriate_body_id"], name: "index_pending_induction_submissions_on_appropriate_body_id"
    t.index ["pending_induction_submission_batch_id"], name: "idx_on_pending_induction_submission_batch_id_bb4509358d"
    t.index ["trn"], name: "index_pending_induction_submissions_on_trn"
  end

  create_table "schedules", force: :cascade do |t|
    t.integer "contract_period_year", null: false
    t.enum "identifier", null: false, enum_type: "schedule_identifiers"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_period_year", "identifier"], name: "index_schedules_on_contract_period_year_and_identifier", unique: true
  end

  create_table "school_partnerships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "lead_provider_delivery_partnership_id", null: false
    t.bigint "school_id", null: false
    t.uuid "api_id", default: -> { "gen_random_uuid()" }, null: false
    t.datetime "api_updated_at", default: -> { "CURRENT_TIMESTAMP" }
    t.index ["api_id"], name: "index_school_partnerships_on_api_id", unique: true
    t.index ["lead_provider_delivery_partnership_id"], name: "idx_on_lead_provider_delivery_partnership_id_628487f752"
    t.index ["school_id", "lead_provider_delivery_partnership_id"], name: "idx_on_school_id_lead_provider_delivery_partnership_7b2d6a6684", unique: true
  end

  create_table "schools", force: :cascade do |t|
    t.integer "urn", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "last_chosen_appropriate_body_id"
    t.bigint "last_chosen_lead_provider_id"
    t.enum "last_chosen_training_programme", enum_type: "training_programme"
    t.datetime "api_updated_at", default: -> { "CURRENT_TIMESTAMP" }
    t.string "induction_tutor_name"
    t.citext "induction_tutor_email"
    t.uuid "api_id", default: -> { "gen_random_uuid()" }, null: false
    t.index ["api_id"], name: "index_schools_on_api_id", unique: true
    t.index ["last_chosen_appropriate_body_id"], name: "index_schools_on_last_chosen_appropriate_body_id"
    t.index ["last_chosen_lead_provider_id"], name: "index_schools_on_last_chosen_lead_provider_id"
    t.index ["urn"], name: "schools_unique_urn", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "statement_adjustments", force: :cascade do |t|
    t.bigint "statement_id", null: false
    t.uuid "ecf_id"
    t.string "payment_type", null: false
    t.decimal "amount", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ecf_id"], name: "index_statement_adjustments_on_ecf_id", unique: true
    t.index ["statement_id"], name: "index_statement_adjustments_on_statement_id"
  end

  create_table "statements", force: :cascade do |t|
    t.bigint "active_lead_provider_id", null: false
    t.uuid "api_id", default: -> { "gen_random_uuid()" }, null: false
    t.integer "month", null: false
    t.integer "year", null: false
    t.date "deadline_date", null: false
    t.date "payment_date", null: false
    t.datetime "marked_as_paid_at"
    t.enum "status", default: "open", null: false, enum_type: "statement_statuses"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.enum "fee_type", default: "output", null: false, enum_type: "fee_types"
    t.datetime "api_updated_at", default: -> { "CURRENT_TIMESTAMP" }
    t.index ["active_lead_provider_id"], name: "index_statements_on_active_lead_provider_id"
  end

  create_table "teacher_id_changes", force: :cascade do |t|
    t.bigint "teacher_id", null: false
    t.uuid "api_from_teacher_id", null: false
    t.uuid "api_to_teacher_id", null: false
    t.uuid "ecf_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_from_teacher_id"], name: "index_teacher_id_changes_on_api_from_teacher_id"
    t.index ["api_to_teacher_id"], name: "index_teacher_id_changes_on_api_to_teacher_id"
    t.index ["ecf_id"], name: "index_teacher_id_changes_on_ecf_id", unique: true
    t.index ["teacher_id"], name: "index_teacher_id_changes_on_teacher_id"
  end

  create_table "teacher_migration_failures", force: :cascade do |t|
    t.bigint "teacher_id"
    t.string "message", null: false
    t.uuid "migration_item_id"
    t.string "migration_item_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "model", default: "teacher", null: false
    t.index ["model"], name: "index_teacher_migration_failures_on_model"
    t.index ["teacher_id"], name: "index_teacher_migration_failures_on_teacher_id"
  end

  create_table "teachers", force: :cascade do |t|
    t.string "corrected_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "trn"
    t.string "trs_first_name"
    t.string "trs_last_name"
    t.date "trs_qts_awarded_on"
    t.string "trs_qts_status_description"
    t.string "trs_induction_status", limit: 18
    t.string "trs_initial_teacher_training_provider_name"
    t.date "trs_initial_teacher_training_end_date"
    t.datetime "trs_data_last_refreshed_at", precision: nil
    t.date "mentor_became_ineligible_for_funding_on"
    t.enum "mentor_became_ineligible_for_funding_reason", enum_type: "mentor_became_ineligible_for_funding_reason"
    t.boolean "trs_deactivated", default: false
    t.virtual "search", type: :tsvector, as: "to_tsvector('unaccented'::regconfig, (((((COALESCE(trs_first_name, ''::character varying))::text || ' '::text) || (COALESCE(trs_last_name, ''::character varying))::text) || ' '::text) || (COALESCE(corrected_name, ''::character varying))::text))", stored: true
    t.uuid "api_id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "api_ect_training_record_id"
    t.uuid "api_mentor_training_record_id"
    t.integer "ect_payments_frozen_year"
    t.integer "mentor_payments_frozen_year"
    t.boolean "ect_pupil_premium_uplift", default: false, null: false
    t.boolean "ect_sparsity_uplift", default: false, null: false
    t.date "trs_induction_start_date"
    t.date "trs_induction_completed_date"
    t.datetime "ect_first_became_eligible_for_training_at"
    t.datetime "mentor_first_became_eligible_for_training_at"
    t.boolean "trnless", default: false, null: false
    t.datetime "api_updated_at", default: -> { "CURRENT_TIMESTAMP" }
    t.index ["api_ect_training_record_id"], name: "index_teachers_on_api_ect_training_record_id", unique: true
    t.index ["api_id"], name: "index_teachers_on_api_id", unique: true
    t.index ["api_mentor_training_record_id"], name: "index_teachers_on_api_mentor_training_record_id", unique: true
    t.index ["api_updated_at"], name: "index_teachers_on_api_updated_at"
    t.index ["corrected_name"], name: "index_teachers_on_corrected_name"
    t.index ["created_at"], name: "index_teachers_on_created_at"
    t.index ["search"], name: "index_teachers_on_search", using: :gin
    t.index ["trn"], name: "index_teachers_on_trn", unique: true
    t.index ["trs_first_name", "trs_last_name", "corrected_name"], name: "idx_on_trs_first_name_trs_last_name_corrected_name_6d0edad502", opclass: :gin_trgm_ops, using: :gin
    t.check_constraint "trnless OR trn IS NOT NULL", name: "check_trn_presence"
  end

  create_table "training_periods", force: :cascade do |t|
    t.bigint "school_partnership_id"
    t.date "started_on", null: false
    t.date "finished_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "ect_at_school_period_id"
    t.bigint "mentor_at_school_period_id"
    t.virtual "range", type: :daterange, as: "daterange(started_on, finished_on)", stored: true
    t.uuid "ecf_start_induction_record_id"
    t.uuid "ecf_end_induction_record_id"
    t.bigint "expression_of_interest_id"
    t.enum "training_programme", null: false, enum_type: "training_programme"
    t.datetime "deferred_at"
    t.enum "deferral_reason", enum_type: "deferral_reasons"
    t.datetime "withdrawn_at"
    t.enum "withdrawal_reason", enum_type: "withdrawal_reasons"
    t.bigint "schedule_id"
    t.index "ect_at_school_period_id, mentor_at_school_period_id, ((finished_on IS NULL))", name: "idx_on_ect_at_school_period_id_mentor_at_school_per_42bce3bf48", unique: true, where: "(finished_on IS NULL)"
    t.index ["ect_at_school_period_id", "mentor_at_school_period_id", "started_on"], name: "idx_on_ect_at_school_period_id_mentor_at_school_per_70f2bb1a45", unique: true
    t.index ["ect_at_school_period_id"], name: "index_training_periods_on_ect_at_school_period_id"
    t.index ["expression_of_interest_id"], name: "index_training_periods_on_expression_of_interest_id"
    t.index ["mentor_at_school_period_id"], name: "index_training_periods_on_mentor_at_school_period_id"
    t.index ["schedule_id"], name: "index_training_periods_on_schedule_id"
    t.index ["school_partnership_id", "ect_at_school_period_id", "mentor_at_school_period_id", "started_on"], name: "provider_partnership_trainings", unique: true
    t.index ["school_partnership_id"], name: "index_training_periods_on_school_partnership_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.citext "email", null: false
    t.string "otp_secret"
    t.datetime "otp_verified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.enum "role", default: "admin", null: false, enum_type: "dfe_role_type"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_lead_providers", "contract_periods", column: "contract_period_year", primary_key: "year"
  add_foreign_key "active_lead_providers", "lead_providers"
  add_foreign_key "ect_at_school_periods", "appropriate_bodies", column: "school_reported_appropriate_body_id"
  add_foreign_key "ect_at_school_periods", "schools"
  add_foreign_key "ect_at_school_periods", "teachers"
  add_foreign_key "events", "active_lead_providers", on_delete: :nullify
  add_foreign_key "events", "appropriate_bodies", on_delete: :nullify
  add_foreign_key "events", "delivery_partners", on_delete: :nullify
  add_foreign_key "events", "ect_at_school_periods", on_delete: :nullify
  add_foreign_key "events", "induction_extensions", on_delete: :nullify
  add_foreign_key "events", "induction_periods", on_delete: :nullify
  add_foreign_key "events", "lead_provider_delivery_partnerships", on_delete: :nullify
  add_foreign_key "events", "lead_providers", on_delete: :nullify
  add_foreign_key "events", "mentor_at_school_periods", on_delete: :nullify
  add_foreign_key "events", "mentorship_periods", on_delete: :nullify
  add_foreign_key "events", "schedules"
  add_foreign_key "events", "school_partnerships", on_delete: :nullify
  add_foreign_key "events", "schools", on_delete: :nullify
  add_foreign_key "events", "statement_adjustments", on_delete: :nullify
  add_foreign_key "events", "statements", on_delete: :nullify
  add_foreign_key "events", "teachers", on_delete: :nullify
  add_foreign_key "events", "training_periods", on_delete: :nullify
  add_foreign_key "events", "users", column: "author_id", on_delete: :nullify
  add_foreign_key "events", "users", on_delete: :nullify
  add_foreign_key "gias_school_links", "gias_schools", column: "urn", primary_key: "urn"
  add_foreign_key "induction_extensions", "teachers"
  add_foreign_key "induction_periods", "appropriate_bodies"
  add_foreign_key "induction_periods", "teachers"
  add_foreign_key "mentor_at_school_periods", "schools"
  add_foreign_key "mentor_at_school_periods", "teachers"
  add_foreign_key "mentorship_periods", "ect_at_school_periods"
  add_foreign_key "mentorship_periods", "mentor_at_school_periods"
  add_foreign_key "metadata_delivery_partners_lead_providers", "delivery_partners"
  add_foreign_key "metadata_delivery_partners_lead_providers", "lead_providers"
  add_foreign_key "metadata_schools_contract_periods", "contract_periods", column: "contract_period_year", primary_key: "year"
  add_foreign_key "metadata_schools_contract_periods", "schools"
  add_foreign_key "metadata_schools_lead_providers_contract_periods", "contract_periods", column: "contract_period_year", primary_key: "year"
  add_foreign_key "metadata_schools_lead_providers_contract_periods", "lead_providers"
  add_foreign_key "metadata_schools_lead_providers_contract_periods", "schools"
  add_foreign_key "metadata_teachers_lead_providers", "contract_periods", column: "latest_ect_contract_period_year", primary_key: "year"
  add_foreign_key "metadata_teachers_lead_providers", "contract_periods", column: "latest_mentor_contract_period_year", primary_key: "year"
  add_foreign_key "metadata_teachers_lead_providers", "lead_providers"
  add_foreign_key "metadata_teachers_lead_providers", "teachers"
  add_foreign_key "metadata_teachers_lead_providers", "training_periods", column: "latest_ect_training_period_id", on_delete: :nullify
  add_foreign_key "metadata_teachers_lead_providers", "training_periods", column: "latest_mentor_training_period_id", on_delete: :nullify
  add_foreign_key "milestones", "schedules"
  add_foreign_key "parity_check_requests", "lead_providers"
  add_foreign_key "parity_check_requests", "parity_check_endpoints", column: "endpoint_id"
  add_foreign_key "parity_check_requests", "parity_check_runs", column: "run_id"
  add_foreign_key "parity_check_responses", "parity_check_requests", column: "request_id"
  add_foreign_key "pending_induction_submission_batches", "appropriate_bodies"
  add_foreign_key "pending_induction_submissions", "appropriate_bodies"
  add_foreign_key "pending_induction_submissions", "pending_induction_submission_batches"
  add_foreign_key "schedules", "contract_periods", column: "contract_period_year", primary_key: "year"
  add_foreign_key "school_partnerships", "schools"
  add_foreign_key "schools", "appropriate_bodies", column: "last_chosen_appropriate_body_id"
  add_foreign_key "schools", "gias_schools", column: "urn", primary_key: "urn"
  add_foreign_key "schools", "lead_providers", column: "last_chosen_lead_provider_id"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "statement_adjustments", "statements"
  add_foreign_key "statements", "active_lead_providers"
  add_foreign_key "teacher_id_changes", "teachers"
  add_foreign_key "teacher_id_changes", "teachers", column: "api_from_teacher_id", primary_key: "api_id"
  add_foreign_key "teacher_id_changes", "teachers", column: "api_to_teacher_id", primary_key: "api_id"
  add_foreign_key "teacher_migration_failures", "teachers"
  add_foreign_key "teachers", "contract_periods", column: "ect_payments_frozen_year", primary_key: "year"
  add_foreign_key "teachers", "contract_periods", column: "mentor_payments_frozen_year", primary_key: "year"
  add_foreign_key "training_periods", "active_lead_providers", column: "expression_of_interest_id"
  add_foreign_key "training_periods", "ect_at_school_periods"
  add_foreign_key "training_periods", "mentor_at_school_periods"
  add_foreign_key "training_periods", "schedules"
  add_foreign_key "training_periods", "school_partnerships"
end
