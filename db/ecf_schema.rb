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

ActiveRecord::Schema[7.1].define(version: 2025_02_28_135429) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "fuzzystrmatch"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "additional_school_emails", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "school_id", null: false
    t.string "email_address", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address", "school_id"], name: "index_additional_school_emails_on_email_address_and_school_id", unique: true
    t.index ["school_id"], name: "index_additional_school_emails_on_school_id"
  end

  create_table "admin_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at", precision: nil
    t.boolean "super_user", default: false
    t.index ["discarded_at"], name: "index_admin_profiles_on_discarded_at"
    t.index ["user_id"], name: "index_admin_profiles_on_user_id"
  end

  create_table "analytics_appropriate_bodies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "appropriate_body_id"
    t.string "name"
    t.string "body_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "analytics_inductions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "induction_record_id"
    t.string "external_id"
    t.uuid "participant_profile_id"
    t.uuid "induction_programme_id"
    t.string "induction_programme_type"
    t.string "school_name"
    t.string "school_urn"
    t.string "schedule_id"
    t.uuid "mentor_id"
    t.uuid "appropriate_body_id"
    t.string "appropriate_body_name"
    t.datetime "start_date", precision: nil
    t.datetime "end_date", precision: nil
    t.string "induction_status"
    t.string "training_status"
    t.boolean "school_transfer"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "cohort_id"
    t.uuid "user_id"
    t.string "participant_type"
    t.datetime "induction_record_created_at", precision: nil
    t.uuid "partnership_id"
    t.index ["induction_record_id"], name: "index_analytics_inductions_on_induction_record_id", unique: true
  end

  create_table "analytics_participants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "user_id"
    t.datetime "user_created_at", precision: nil
    t.integer "real_time_attempts"
    t.boolean "real_time_success"
    t.datetime "validation_submitted_at", precision: nil
    t.boolean "trn_verified"
    t.string "school_urn"
    t.string "school_name"
    t.string "establishment_phase_name"
    t.string "participant_type"
    t.string "participant_profile_id"
    t.string "cohort"
    t.string "mentor_id"
    t.boolean "nino_entered"
    t.boolean "manually_validated"
    t.boolean "eligible_for_funding"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true
    t.string "training_status"
    t.boolean "sparsity"
    t.boolean "pupil_premium"
    t.string "schedule_identifier"
    t.string "external_id"
    t.index ["participant_profile_id"], name: "index_analytics_participants_on_participant_profile_id"
  end

  create_table "analytics_partnerships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "partnership_id"
    t.uuid "school_id"
    t.string "school_name"
    t.string "school_urn"
    t.uuid "lead_provider_id"
    t.string "lead_provider_name"
    t.uuid "cohort_id"
    t.string "cohort"
    t.uuid "delivery_partner_id"
    t.string "delivery_partner_name"
    t.datetime "challenged_at", precision: nil
    t.string "challenge_reason"
    t.datetime "challenge_deadline", precision: nil
    t.boolean "pending"
    t.uuid "report_id"
    t.boolean "relationship"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "analytics_school_cohorts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "school_cohort_id"
    t.uuid "school_id"
    t.string "school_name"
    t.string "school_urn"
    t.uuid "cohort_id"
    t.string "cohort"
    t.string "induction_programme_choice"
    t.string "default_induction_programme_training_choice"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "appropriate_body_id"
  end

  create_table "analytics_schools", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "urn", null: false
    t.datetime "nomination_email_opened_at", precision: nil
    t.boolean "induction_tutor_nominated"
    t.datetime "tutor_nominated_time", precision: nil
    t.boolean "induction_tutor_signed_in"
    t.string "induction_programme_choice"
    t.boolean "in_partnership"
    t.datetime "partnership_time", precision: nil
    t.string "partnership_challenge_reason"
    t.string "partnership_challenge_time"
    t.string "lead_provider"
    t.string "delivery_partner"
    t.string "chosen_cip"
    t.string "school_type_name"
    t.integer "school_phase_type"
    t.string "school_phase_name"
    t.integer "school_status_code"
    t.string "school_status_name"
    t.string "postcode"
    t.string "administrative_district_code"
    t.string "administrative_district_name"
    t.boolean "active_participants"
    t.boolean "pupil_premium"
    t.boolean "sparsity"
    t.index ["urn"], name: "index_analytics_schools_on_urn", unique: true
  end

  create_table "api_request_audits", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "path"
    t.jsonb "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "api_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "request_path"
    t.integer "status_code"
    t.jsonb "request_headers"
    t.jsonb "request_body"
    t.jsonb "response_body"
    t.string "request_method"
    t.jsonb "response_headers"
    t.uuid "cpd_lead_provider_id"
    t.string "user_description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cpd_lead_provider_id"], name: "index_api_requests_on_cpd_lead_provider_id"
  end

  create_table "api_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "lead_provider_id"
    t.string "hashed_token", null: false
    t.datetime "last_used_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type", default: "ApiToken"
    t.boolean "private_api_access", default: false
    t.uuid "cpd_lead_provider_id"
    t.index ["cpd_lead_provider_id"], name: "index_api_tokens_on_cpd_lead_provider_id"
    t.index ["hashed_token"], name: "index_api_tokens_on_hashed_token", unique: true
    t.index ["lead_provider_id"], name: "index_api_tokens_on_lead_provider_id"
  end

  create_table "appropriate_bodies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "body_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "disable_from_year"
    t.boolean "listed", default: false, null: false
    t.integer "listed_for_school_type_codes", default: [], array: true
    t.boolean "selectable_by_schools", default: true, null: false
    t.index ["body_type", "name"], name: "index_appropriate_bodies_on_body_type_and_name", unique: true
  end

  create_table "appropriate_body_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "appropriate_body_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appropriate_body_id"], name: "index_appropriate_body_profiles_on_appropriate_body_id"
    t.index ["user_id"], name: "index_appropriate_body_profiles_on_user_id"
  end

  create_table "archive_relics", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "object_type", null: false
    t.string "object_id", null: false
    t.string "display_name", null: false
    t.string "reason", null: false
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "((data -> 'meta'::text))", name: "index_archive_relics_on_data_meta", using: :gin
    t.index ["display_name"], name: "index_archive_relics_on_display_name"
    t.index ["object_id"], name: "index_archive_relics_on_object_id"
    t.index ["object_type"], name: "index_archive_relics_on_object_type"
    t.index ["reason"], name: "index_archive_relics_on_reason"
  end

  create_table "call_off_contracts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "version", default: "0.0.1", null: false
    t.jsonb "raw"
    t.decimal "uplift_target"
    t.decimal "uplift_amount"
    t.integer "recruitment_target"
    t.decimal "set_up_fee"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "lead_provider_id", default: -> { "gen_random_uuid()" }, null: false
    t.integer "revised_target"
    t.uuid "cohort_id", null: false
    t.decimal "monthly_service_fee"
    t.index ["cohort_id"], name: "index_call_off_contracts_on_cohort_id"
    t.index ["lead_provider_id"], name: "index_call_off_contracts_on_lead_provider_id"
  end

  create_table "cohorts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "start_year", limit: 2, null: false
    t.datetime "registration_start_date", precision: nil
    t.datetime "academic_year_start_date", precision: nil
    t.date "automatic_assignment_period_end_date"
    t.datetime "payments_frozen_at"
    t.boolean "mentor_funding", default: false, null: false
    t.boolean "detailed_evidence_types", default: false, null: false
    t.index ["start_year"], name: "index_cohorts_on_start_year", unique: true
  end

  create_table "cohorts_lead_providers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "lead_provider_id", null: false
    t.uuid "cohort_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cohort_id", "lead_provider_id"], name: "index_cohorts_lead_providers_on_cohort_id_and_lead_provider_id"
    t.index ["lead_provider_id", "cohort_id"], name: "index_cohorts_lead_providers_on_lead_provider_id_and_cohort_id"
  end

  create_table "completion_candidates", id: false, force: :cascade do |t|
    t.uuid "participant_profile_id"
    t.index ["participant_profile_id"], name: "index_completion_candidates_on_participant_profile_id", unique: true
  end

  create_table "continue_training_cohort_change_errors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "participant_profile_id", null: false
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_profile_id"], name: "continue_training_error_participant_profile_id"
  end

  create_table "core_induction_programmes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cpd_lead_providers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "data_stage_school_changes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "data_stage_school_id", null: false
    t.json "attribute_changes"
    t.string "status", default: "changed", null: false
    t.boolean "handled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["data_stage_school_id"], name: "index_data_stage_school_changes_on_data_stage_school_id"
    t.index ["status"], name: "index_data_stage_school_changes_on_status"
  end

  create_table "data_stage_school_links", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "data_stage_school_id", null: false
    t.string "link_urn", null: false
    t.string "link_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["data_stage_school_id", "link_urn"], name: "data_stage_school_links_uniq_idx", unique: true
    t.index ["data_stage_school_id"], name: "index_data_stage_school_links_on_data_stage_school_id"
  end

  create_table "data_stage_schools", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "urn", null: false
    t.string "name", null: false
    t.string "ukprn"
    t.integer "school_phase_type"
    t.string "school_phase_name"
    t.integer "school_type_code"
    t.string "school_type_name"
    t.integer "school_status_code"
    t.string "school_status_name"
    t.string "administrative_district_code"
    t.string "administrative_district_name"
    t.string "address_line1", null: false
    t.string "address_line2"
    t.string "address_line3"
    t.string "postcode", null: false
    t.string "primary_contact_email"
    t.string "secondary_contact_email"
    t.string "school_website"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "section_41_approved"
    t.string "la_code"
    t.index ["urn"], name: "index_data_stage_schools_on_urn", unique: true
  end

  create_table "declaration_states", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "participant_declaration_id", null: false
    t.string "state", default: "submitted", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state_reason"
    t.index ["participant_declaration_id"], name: "index_declaration_states_on_participant_declaration_id"
  end

  create_table "deleted_duplicates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "data"
    t.uuid "primary_participant_profile_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["primary_participant_profile_id"], name: "index_deleted_duplicates_on_primary_participant_profile_id"
  end

  create_table "delivery_partner_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "delivery_partner_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_partner_id"], name: "index_delivery_partner_profiles_on_delivery_partner_id"
    t.index ["user_id"], name: "index_delivery_partner_profiles_on_user_id"
  end

  create_table "delivery_partners", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.datetime "discarded_at", precision: nil
    t.index ["discarded_at"], name: "index_delivery_partners_on_discarded_at"
  end

  create_table "district_sparsities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "local_authority_district_id", null: false
    t.integer "start_year", limit: 2, null: false
    t.integer "end_year", limit: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["local_authority_district_id"], name: "index_district_sparsities_on_local_authority_district_id"
  end

  create_table "ecf_ineligible_participants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "trn"
    t.string "reason", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["trn"], name: "index_ecf_ineligible_participants_on_trn", unique: true
  end

  create_table "ecf_participant_eligibilities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "participant_profile_id", null: false
    t.boolean "qts"
    t.boolean "active_flags"
    t.boolean "previous_participation"
    t.boolean "previous_induction"
    t.boolean "manually_validated", default: false
    t.string "status", default: "manual_check", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reason", default: "none", null: false
    t.boolean "different_trn"
    t.boolean "no_induction"
    t.boolean "exempt_from_induction"
    t.index ["participant_profile_id"], name: "index_ecf_participant_eligibilities_on_participant_profile_id", unique: true
  end

  create_table "ecf_participant_validation_data", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "participant_profile_id", null: false
    t.string "full_name"
    t.date "date_of_birth"
    t.string "trn"
    t.string "nino"
    t.boolean "api_failure", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_profile_id"], name: "index_ecf_participant_validation_data_on_participant_profile_id", unique: true
  end

  create_table "ecf_schools", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "urn"
    t.datetime "nomination_email_opened_at", precision: nil
    t.boolean "induction_tutor_nominated"
    t.datetime "tutor_nominated_time", precision: nil
    t.boolean "induction_tutor_signed_in"
    t.string "induction_programme_choice"
    t.boolean "in_partnership"
    t.datetime "partnership_time", precision: nil
    t.string "partnership_challenge_reason"
    t.string "partnership_challenge_time"
    t.string "lead_provider"
    t.string "delivery_partner"
    t.string "chosen_cip"
    t.string "school_type_name"
    t.integer "school_phase_type"
    t.string "school_phase_name"
    t.integer "school_status_code"
    t.string "school_status_name"
    t.string "postcode"
    t.string "administrative_district_code"
    t.string "administrative_district_name"
    t.boolean "active_participants"
    t.boolean "pupil_premium"
    t.boolean "sparsity"
    t.index ["urn"], name: "index_ecf_schools_on_urn", unique: true
  end

  create_table "email_associations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "email_id", null: false
    t.string "object_type", null: false
    t.uuid "object_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_id"], name: "index_email_associations_on_email_id"
    t.index ["object_type", "object_id"], name: "index_email_associations_on_object"
  end

  create_table "email_schedules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "mailer_name", null: false
    t.date "scheduled_at", null: false
    t.string "status", default: "queued", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "emails_sent_count"
  end

  create_table "emails", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "from"
    t.string "to", array: true
    t.uuid "template_id"
    t.integer "template_version"
    t.string "uri"
    t.jsonb "personalisation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "submitted", null: false
    t.datetime "delivered_at", precision: nil
    t.string "tags", default: [], null: false, array: true
  end

  create_table "event_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "owner_type", null: false
    t.uuid "owner_id", null: false
    t.string "event", null: false
    t.json "data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_event_logs_on_owner"
  end

  create_table "feature_selected_objects", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "object_type", null: false
    t.uuid "object_id", null: false
    t.uuid "feature_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_id"], name: "index_feature_selected_objects_on_feature_id"
    t.index ["object_id", "feature_id", "object_type"], name: "unique_selected_object", unique: true
    t.index ["object_type", "object_id"], name: "index_feature_selected_objects_on_object"
  end

  create_table "features", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.boolean "active", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_features_on_name", unique: true
  end

  create_table "finance_adjustments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "statement_id", null: false
    t.string "payment_type", null: false
    t.decimal "amount", default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["statement_id"], name: "index_finance_adjustments_on_statement_id"
  end

  create_table "finance_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_finance_profiles_on_user_id"
  end

  create_table "friendly_id_slugs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at", precision: nil
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "induction_coordinator_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at", precision: nil
    t.datetime "reminder_email_sent_at", precision: nil
    t.index ["discarded_at"], name: "index_induction_coordinator_profiles_on_discarded_at"
    t.index ["user_id"], name: "index_induction_coordinator_profiles_on_user_id"
  end

  create_table "induction_coordinator_profiles_schools", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "induction_coordinator_profile_id", null: false
    t.uuid "school_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["induction_coordinator_profile_id"], name: "index_icp_schools_on_icp"
    t.index ["school_id"], name: "index_icp_schools_on_schools"
  end

  create_table "induction_programmes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "school_cohort_id", null: false
    t.uuid "partnership_id"
    t.uuid "core_induction_programme_id"
    t.string "training_programme", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "delivery_partner_to_be_confirmed", default: false
    t.index ["core_induction_programme_id"], name: "index_induction_programmes_on_core_induction_programme_id"
    t.index ["partnership_id"], name: "index_induction_programmes_on_partnership_id"
    t.index ["school_cohort_id"], name: "index_induction_programmes_on_school_cohort_id"
  end

  create_table "induction_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "induction_programme_id", null: false
    t.uuid "participant_profile_id", null: false
    t.uuid "schedule_id", null: false
    t.datetime "start_date", precision: nil, null: false
    t.datetime "end_date", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "training_status", default: "active", null: false
    t.uuid "preferred_identity_id"
    t.string "induction_status", default: "active", null: false
    t.uuid "mentor_profile_id"
    t.boolean "school_transfer", default: false, null: false
    t.uuid "appropriate_body_id"
    t.index ["appropriate_body_id"], name: "index_induction_records_on_appropriate_body_id"
    t.index ["created_at"], name: "index_induction_records_on_created_at"
    t.index ["end_date"], name: "index_induction_records_on_end_date"
    t.index ["induction_programme_id"], name: "index_induction_records_on_induction_programme_id"
    t.index ["mentor_profile_id"], name: "index_induction_records_on_mentor_profile_id"
    t.index ["participant_profile_id"], name: "index_induction_records_on_participant_profile_id"
    t.index ["preferred_identity_id"], name: "index_induction_records_on_preferred_identity_id"
    t.index ["schedule_id"], name: "index_induction_records_on_schedule_id"
    t.index ["start_date"], name: "index_induction_records_on_start_date"
  end

  create_table "lead_provider_cips", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "lead_provider_id", null: false
    t.uuid "cohort_id", null: false
    t.uuid "core_induction_programme_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cohort_id"], name: "index_lead_provider_cips_on_cohort_id"
    t.index ["core_induction_programme_id"], name: "index_lead_provider_cips_on_core_induction_programme_id"
    t.index ["lead_provider_id"], name: "index_lead_provider_cips_on_lead_provider_id"
  end

  create_table "lead_provider_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "lead_provider_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at", precision: nil
    t.index ["discarded_at"], name: "index_lead_provider_profiles_on_discarded_at"
    t.index ["lead_provider_id"], name: "index_lead_provider_profiles_on_lead_provider_id"
    t.index ["user_id"], name: "index_lead_provider_profiles_on_user_id"
  end

  create_table "lead_providers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.uuid "cpd_lead_provider_id"
    t.boolean "vat_chargeable", default: true
    t.index ["cpd_lead_provider_id"], name: "index_lead_providers_on_cpd_lead_provider_id"
  end

  create_table "local_authorities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "code"
    t.string "name"
    t.index ["code"], name: "index_local_authorities_on_code", unique: true
  end

  create_table "local_authority_districts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "code"
    t.string "name"
    t.index ["code"], name: "index_local_authority_districts_on_code", unique: true
  end

  create_table "mentor_call_off_contracts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "lead_provider_id", null: false
    t.uuid "cohort_id", null: false
    t.string "version", default: "0.0.1", null: false
    t.integer "recruitment_target"
    t.decimal "payment_per_participant", default: "1000.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cohort_id"], name: "index_mentor_call_off_contracts_on_cohort_id"
    t.index ["lead_provider_id"], name: "index_mentor_call_off_contracts_on_lead_provider_id"
  end

  create_table "milestones", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "name", null: false
    t.date "milestone_date"
    t.date "payment_date", null: false
    t.uuid "schedule_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "start_date"
    t.string "declaration_type"
    t.index ["schedule_id"], name: "index_milestones_on_schedule_id"
  end

  create_table "networks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.string "group_type"
    t.string "group_type_code"
    t.string "group_id"
    t.string "group_uid"
    t.string "secondary_contact_email"
  end

  create_table "nomination_emails", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "token", null: false
    t.string "notify_status"
    t.string "sent_to", null: false
    t.datetime "sent_at", precision: nil
    t.datetime "opened_at", precision: nil
    t.uuid "school_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "partnership_notification_email_id"
    t.string "notify_id"
    t.datetime "delivered_at", precision: nil
    t.index ["notify_id"], name: "index_nomination_emails_on_notify_id"
    t.index ["partnership_notification_email_id"], name: "index_nomination_emails_on_partnership_notification_email_id"
    t.index ["school_id"], name: "index_nomination_emails_on_school_id"
    t.index ["token"], name: "index_nomination_emails_on_token", unique: true
  end

  create_table "participant_appropriate_body_dqt_checks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "participant_profile_id", null: false
    t.string "appropriate_body_name"
    t.string "dqt_appropriate_body_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "dqt_induction_status"
  end

  create_table "participant_bands", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "call_off_contract_id", null: false
    t.integer "min"
    t.integer "max"
    t.decimal "per_participant"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "output_payment_percentage", default: 60
    t.integer "service_fee_percentage", default: 40
    t.index ["call_off_contract_id"], name: "index_participant_bands_on_call_off_contract_id"
  end

  create_table "participant_declaration_attempts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "declaration_type"
    t.datetime "declaration_date", precision: nil
    t.uuid "user_id"
    t.string "course_identifier"
    t.string "evidence_held"
    t.uuid "cpd_lead_provider_id"
    t.uuid "participant_declaration_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_declaration_id"], name: "index_declaration_attempts_on_declarations"
  end

  create_table "participant_declarations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "declaration_type"
    t.datetime "declaration_date", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.string "course_identifier"
    t.string "evidence_held"
    t.string "type", default: "ParticipantDeclaration::ECF"
    t.uuid "cpd_lead_provider_id"
    t.string "state", default: "submitted", null: false
    t.uuid "participant_profile_id"
    t.uuid "superseded_by_id"
    t.boolean "sparsity_uplift"
    t.boolean "pupil_premium_uplift"
    t.uuid "delivery_partner_id"
    t.uuid "mentor_user_id"
    t.uuid "cohort_id", null: false
    t.datetime "voided_at"
    t.uuid "voided_by_user_id"
    t.index ["cohort_id"], name: "index_participant_declarations_on_cohort_id"
    t.index ["cpd_lead_provider_id", "participant_profile_id", "declaration_type", "course_identifier", "state"], name: "unique_declaration_index", unique: true, where: "((state)::text = ANY (ARRAY[('submitted'::character varying)::text, ('eligible'::character varying)::text, ('payable'::character varying)::text, ('paid'::character varying)::text]))"
    t.index ["cpd_lead_provider_id"], name: "index_participant_declarations_on_cpd_lead_provider_id"
    t.index ["declaration_type"], name: "index_participant_declarations_on_declaration_type"
    t.index ["delivery_partner_id"], name: "index_participant_declarations_on_delivery_partner_id"
    t.index ["mentor_user_id"], name: "index_participant_declarations_on_mentor_user_id"
    t.index ["participant_profile_id"], name: "index_participant_declarations_on_participant_profile_id"
    t.index ["superseded_by_id"], name: "superseded_by_index"
    t.index ["type"], name: "index_participant_declarations_on_type"
    t.index ["user_id"], name: "index_participant_declarations_on_user_id"
    t.index ["voided_by_user_id"], name: "index_participant_declarations_on_voided_by_user_id"
  end

  create_table "participant_id_changes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "from_participant_id", null: false
    t.uuid "to_participant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_participant_id"], name: "index_participant_id_changes_on_from_participant_id"
    t.index ["to_participant_id"], name: "index_participant_id_changes_on_to_participant_id"
    t.index ["user_id"], name: "index_participant_id_changes_on_user_id"
  end

  create_table "participant_identities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.citext "email", null: false
    t.uuid "external_identifier", null: false
    t.string "origin", default: "ecf", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_participant_identities_on_email", unique: true
    t.index ["external_identifier"], name: "index_participant_identities_on_external_identifier", unique: true
    t.index ["user_id"], name: "index_participant_identities_on_user_id"
  end

  create_table "participant_profile_completion_date_inconsistencies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "participant_profile_id", null: false
    t.date "dqt_value"
    t.date "participant_value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_profile_id"], name: "idx_on_participant_profile_id_b55d68e537", unique: true
  end

  create_table "participant_profile_schedules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "participant_profile_id", null: false
    t.uuid "schedule_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_profile_id"], name: "index_participant_profile_schedules_on_participant_profile_id"
    t.index ["schedule_id"], name: "index_participant_profile_schedules_on_schedule_id"
  end

  create_table "participant_profile_states", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "participant_profile_id", null: false
    t.text "state", default: "active"
    t.text "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "cpd_lead_provider_id"
    t.index ["cpd_lead_provider_id"], name: "index_participant_profile_states_on_cpd_lead_provider_id"
    t.index ["participant_profile_id", "cpd_lead_provider_id"], name: "index_on_profile_and_lead_provider"
    t.index ["participant_profile_id", "state", "cpd_lead_provider_id"], name: "index_on_profile_and_state_and_lead_provider"
    t.index ["participant_profile_id"], name: "index_participant_profile_states_on_participant_profile_id"
  end

  create_table "participant_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "type", null: false
    t.uuid "school_id"
    t.uuid "core_induction_programme_id"
    t.uuid "cohort_id"
    t.uuid "mentor_profile_id"
    t.boolean "sparsity_uplift", default: false, null: false
    t.boolean "pupil_premium_uplift", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "status", default: "active", null: false
    t.uuid "school_cohort_id"
    t.uuid "teacher_profile_id"
    t.uuid "schedule_id", null: false
    t.text "school_urn"
    t.text "school_ukprn"
    t.datetime "request_for_details_sent_at", precision: nil
    t.string "training_status", default: "active", null: false
    t.string "profile_duplicity", default: "single", null: false
    t.uuid "participant_identity_id"
    t.string "notes"
    t.date "induction_start_date"
    t.date "induction_completion_date"
    t.date "mentor_completion_date"
    t.string "mentor_completion_reason"
    t.boolean "cohort_changed_after_payments_frozen", default: false
    t.index ["cohort_id"], name: "index_participant_profiles_on_cohort_id"
    t.index ["core_induction_programme_id"], name: "index_participant_profiles_on_core_induction_programme_id"
    t.index ["mentor_profile_id"], name: "index_participant_profiles_on_mentor_profile_id"
    t.index ["participant_identity_id"], name: "index_participant_profiles_on_participant_identity_id"
    t.index ["schedule_id"], name: "index_participant_profiles_on_schedule_id"
    t.index ["school_cohort_id"], name: "index_participant_profiles_on_school_cohort_id"
    t.index ["school_id"], name: "index_participant_profiles_on_school_id"
    t.index ["teacher_profile_id"], name: "index_participant_profiles_on_teacher_profile_id"
  end

  create_table "partnership_csv_uploads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "lead_provider_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "delivery_partner_id", null: false
    t.uuid "cohort_id"
    t.string "uploaded_urns", array: true
    t.index ["cohort_id"], name: "index_partnership_csv_uploads_on_cohort_id"
    t.index ["delivery_partner_id"], name: "index_partnership_csv_uploads_on_delivery_partner_id"
    t.index ["lead_provider_id"], name: "index_partnership_csv_uploads_on_lead_provider_id"
  end

  create_table "partnership_notification_emails", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "token", null: false
    t.string "sent_to", null: false
    t.string "email_type", null: false
    t.string "notify_id"
    t.string "notify_status"
    t.datetime "delivered_at", precision: nil
    t.uuid "partnership_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notify_id"], name: "index_partnership_notification_emails_on_notify_id"
    t.index ["partnership_id"], name: "index_partnership_notification_emails_on_partnership_id"
    t.index ["token"], name: "index_partnership_notification_emails_on_token", unique: true
  end

  create_table "partnerships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "school_id", null: false
    t.uuid "lead_provider_id", null: false
    t.uuid "cohort_id", null: false
    t.uuid "delivery_partner_id"
    t.datetime "challenged_at", precision: nil
    t.string "challenge_reason"
    t.datetime "challenge_deadline", precision: nil
    t.boolean "pending", default: false, null: false
    t.uuid "report_id"
    t.boolean "relationship", default: false, null: false
    t.index ["cohort_id"], name: "index_partnerships_on_cohort_id"
    t.index ["delivery_partner_id"], name: "index_partnerships_on_delivery_partner_id"
    t.index ["lead_provider_id"], name: "index_partnerships_on_lead_provider_id"
    t.index ["pending"], name: "index_partnerships_on_pending"
    t.index ["school_id", "lead_provider_id", "delivery_partner_id", "cohort_id"], name: "unique_partnerships", unique: true
    t.index ["school_id"], name: "index_partnerships_on_school_id"
  end

  create_table "privacy_policies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "major_version", null: false
    t.integer "minor_version", null: false
    t.text "html", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["major_version", "minor_version"], name: "index_privacy_policies_on_major_version_and_minor_version", unique: true
  end

  create_table "privacy_policy_acceptances", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "privacy_policy_id"
    t.uuid "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["privacy_policy_id", "user_id"], name: "single-acceptance", unique: true
  end

  create_table "profile_validation_decisions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "participant_profile_id", null: false
    t.string "validation_step", null: false
    t.boolean "approved"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_profile_id", "validation_step"], name: "unique_validation_step", unique: true
    t.index ["participant_profile_id"], name: "index_profile_validation_decisions_on_participant_profile_id"
  end

  create_table "provider_relationships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "lead_provider_id", null: false
    t.uuid "delivery_partner_id", null: false
    t.uuid "cohort_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at", precision: nil
    t.index ["cohort_id"], name: "index_provider_relationships_on_cohort_id"
    t.index ["delivery_partner_id"], name: "index_provider_relationships_on_delivery_partner_id"
    t.index ["discarded_at"], name: "index_provider_relationships_on_discarded_at"
    t.index ["lead_provider_id"], name: "index_provider_relationships_on_lead_provider_id"
  end

  create_table "pupil_premiums", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "school_id", null: false
    t.integer "start_year", limit: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "pupil_premium_incentive", default: false, null: false
    t.boolean "sparsity_incentive", default: false, null: false
    t.index ["school_id"], name: "index_pupil_premiums_on_school_id"
  end

  create_table "schedule_milestones", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.uuid "schedule_id", null: false
    t.uuid "milestone_id", null: false
    t.string "declaration_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["milestone_id"], name: "index_schedule_milestones_on_milestone_id"
    t.index ["schedule_id"], name: "index_schedule_milestones_on_schedule_id"
  end

  create_table "schedules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "schedule_identifier"
    t.string "type", default: "Finance::Schedule::ECF"
    t.uuid "cohort_id"
    t.text "identifier_alias"
    t.index ["cohort_id"], name: "index_schedules_on_cohort_id"
  end

  create_table "school_cohorts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "induction_programme_choice", null: false
    t.uuid "school_id", null: false
    t.uuid "cohort_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "estimated_teacher_count"
    t.integer "estimated_mentor_count"
    t.uuid "core_induction_programme_id"
    t.boolean "opt_out_of_updates", default: false, null: false
    t.uuid "default_induction_programme_id"
    t.uuid "appropriate_body_id"
    t.index ["appropriate_body_id"], name: "index_school_cohorts_on_appropriate_body_id"
    t.index ["cohort_id"], name: "index_school_cohorts_on_cohort_id"
    t.index ["core_induction_programme_id"], name: "index_school_cohorts_on_core_induction_programme_id"
    t.index ["default_induction_programme_id"], name: "index_school_cohorts_on_default_induction_programme_id"
    t.index ["school_id", "cohort_id"], name: "index_school_cohorts_on_school_id_and_cohort_id", unique: true
    t.index ["school_id"], name: "index_school_cohorts_on_school_id"
    t.index ["updated_at"], name: "index_school_cohorts_on_updated_at"
  end

  create_table "school_links", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "school_id", null: false
    t.string "link_urn", null: false
    t.string "link_type", null: false
    t.string "link_reason", default: "simple", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id"], name: "index_school_links_on_school_id"
  end

  create_table "school_local_authorities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "school_id", null: false
    t.uuid "local_authority_id", null: false
    t.integer "start_year", limit: 2, null: false
    t.integer "end_year", limit: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["local_authority_id"], name: "index_school_local_authorities_on_local_authority_id"
    t.index ["school_id"], name: "index_school_local_authorities_on_school_id"
  end

  create_table "school_local_authority_districts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "school_id", null: false
    t.uuid "local_authority_district_id", null: false
    t.integer "start_year", limit: 2, null: false
    t.integer "end_year", limit: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["local_authority_district_id"], name: "index_schools_lads_on_lad_id"
    t.index ["school_id"], name: "index_school_local_authority_districts_on_school_id"
  end

  create_table "school_mentors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "participant_profile_id", null: false
    t.uuid "school_id", null: false
    t.uuid "preferred_identity_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "remove_from_school_on"
    t.index ["participant_profile_id", "school_id"], name: "index_school_mentors_on_participant_profile_id_and_school_id", unique: true
    t.index ["participant_profile_id"], name: "index_school_mentors_on_participant_profile_id"
    t.index ["preferred_identity_id"], name: "index_school_mentors_on_preferred_identity_id"
    t.index ["school_id"], name: "index_school_mentors_on_school_id"
  end

  create_table "schools", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "urn", null: false
    t.string "name", null: false
    t.integer "school_type_code"
    t.string "address_line1", null: false
    t.string "address_line2"
    t.string "address_line3"
    t.string "postcode", null: false
    t.uuid "network_id"
    t.string "domains", default: [], null: false, array: true
    t.string "school_type_name"
    t.string "ukprn"
    t.integer "school_phase_type"
    t.string "school_phase_name"
    t.string "school_website"
    t.integer "school_status_code"
    t.string "school_status_name"
    t.string "secondary_contact_email"
    t.string "primary_contact_email"
    t.string "administrative_district_code"
    t.string "administrative_district_name"
    t.string "slug"
    t.boolean "section_41_approved", default: false, null: false
    t.index ["name"], name: "index_schools_on_name"
    t.index ["network_id"], name: "index_schools_on_network_id"
    t.index ["school_type_code", "school_status_code"], name: "index_schools_on_school_type_code_and_school_status_code"
    t.index ["section_41_approved", "school_status_code"], name: "index_schools_on_section_41_approved_and_school_status_code", where: "section_41_approved"
    t.index ["slug"], name: "index_schools_on_slug", unique: true
    t.index ["urn"], name: "index_schools_on_urn", unique: true
  end

  create_table "sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "session_id", null: false
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "statement_line_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "statement_id", null: false
    t.uuid "participant_declaration_id", null: false
    t.text "state", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_declaration_id", "statement_id", "state"], name: "unique_declaration_statement_state", unique: true
    t.index ["statement_id", "participant_declaration_id", "state"], name: "unique_statement_declaration_state", unique: true
  end

  create_table "statements", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "type", null: false
    t.text "name", null: false
    t.uuid "cpd_lead_provider_id", null: false
    t.date "deadline_date"
    t.date "payment_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "original_value"
    t.uuid "cohort_id", null: false
    t.boolean "output_fee", default: true
    t.string "contract_version", default: "0.0.1"
    t.decimal "reconcile_amount", default: "0.0", null: false
    t.datetime "marked_as_paid_at"
    t.index ["cohort_id"], name: "index_statements_on_cohort_id"
    t.index ["cpd_lead_provider_id"], name: "index_statements_on_cpd_lead_provider_id"
  end

  create_table "support_queries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.integer "zendesk_ticket_id"
    t.string "subject", null: false
    t.string "message", null: false
    t.jsonb "additional_information", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subject"], name: "index_support_queries_on_subject"
    t.index ["user_id", "subject"], name: "index_support_queries_on_user_id_and_subject"
    t.index ["user_id"], name: "index_support_queries_on_user_id"
  end

  create_table "sync_dqt_induction_start_date_errors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "participant_profile_id", null: false
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_profile_id"], name: "dqt_sync_participant_profile_id"
  end

  create_table "teacher_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "trn"
    t.uuid "school_id"
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id"], name: "index_teacher_profiles_on_school_id"
    t.index ["user_id"], name: "index_teacher_profiles_on_user_id", unique: true
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "full_name", null: false
    t.citext "email", default: "", null: false
    t.string "login_token"
    t.datetime "login_token_valid_until", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.datetime "current_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at", precision: nil
    t.string "get_an_identity_id"
    t.string "archived_email"
    t.datetime "archived_at", precision: nil
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["get_an_identity_id"], name: "index_users_on_get_an_identity_id", unique: true
  end

  create_table "validation_errors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "form_object", null: false
    t.uuid "user_id"
    t.string "request_path", null: false
    t.jsonb "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["form_object"], name: "index_validation_errors_on_form_object"
  end

  create_table "versions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "item_type", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.json "object"
    t.json "object_changes"
    t.datetime "created_at", precision: nil
    t.uuid "item_id", default: -> { "gen_random_uuid()" }, null: false
    t.string "reason"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "additional_school_emails", "schools"
  add_foreign_key "admin_profiles", "users"
  add_foreign_key "api_requests", "cpd_lead_providers"
  add_foreign_key "api_tokens", "cpd_lead_providers"
  add_foreign_key "api_tokens", "lead_providers", on_delete: :cascade
  add_foreign_key "appropriate_body_profiles", "appropriate_bodies"
  add_foreign_key "appropriate_body_profiles", "users"
  add_foreign_key "call_off_contracts", "lead_providers"
  add_foreign_key "cohorts_lead_providers", "cohorts"
  add_foreign_key "cohorts_lead_providers", "lead_providers"
  add_foreign_key "completion_candidates", "participant_profiles", on_delete: :cascade
  add_foreign_key "continue_training_cohort_change_errors", "participant_profiles"
  add_foreign_key "data_stage_school_changes", "data_stage_schools"
  add_foreign_key "data_stage_school_links", "data_stage_schools"
  add_foreign_key "deleted_duplicates", "participant_profiles", column: "primary_participant_profile_id"
  add_foreign_key "delivery_partner_profiles", "delivery_partners"
  add_foreign_key "delivery_partner_profiles", "users"
  add_foreign_key "district_sparsities", "local_authority_districts"
  add_foreign_key "ecf_participant_eligibilities", "participant_profiles"
  add_foreign_key "ecf_participant_validation_data", "participant_profiles"
  add_foreign_key "email_associations", "emails"
  add_foreign_key "feature_selected_objects", "features"
  add_foreign_key "finance_adjustments", "statements"
  add_foreign_key "finance_profiles", "users"
  add_foreign_key "induction_coordinator_profiles", "users"
  add_foreign_key "induction_programmes", "core_induction_programmes"
  add_foreign_key "induction_programmes", "partnerships"
  add_foreign_key "induction_programmes", "school_cohorts"
  add_foreign_key "induction_records", "induction_programmes"
  add_foreign_key "induction_records", "participant_profiles"
  add_foreign_key "induction_records", "schedules"
  add_foreign_key "lead_provider_cips", "cohorts"
  add_foreign_key "lead_provider_cips", "core_induction_programmes"
  add_foreign_key "lead_provider_cips", "lead_providers"
  add_foreign_key "lead_provider_profiles", "lead_providers"
  add_foreign_key "lead_provider_profiles", "users"
  add_foreign_key "lead_providers", "cpd_lead_providers"
  add_foreign_key "mentor_call_off_contracts", "cohorts"
  add_foreign_key "mentor_call_off_contracts", "lead_providers"
  add_foreign_key "milestones", "schedules"
  add_foreign_key "nomination_emails", "partnership_notification_emails"
  add_foreign_key "nomination_emails", "schools"
  add_foreign_key "participant_bands", "call_off_contracts"
  add_foreign_key "participant_declaration_attempts", "participant_declarations"
  add_foreign_key "participant_declarations", "participant_declarations", column: "superseded_by_id"
  add_foreign_key "participant_declarations", "participant_profiles"
  add_foreign_key "participant_declarations", "users"
  add_foreign_key "participant_declarations", "users", column: "mentor_user_id"
  add_foreign_key "participant_declarations", "users", column: "voided_by_user_id"
  add_foreign_key "participant_id_changes", "users"
  add_foreign_key "participant_identities", "users"
  add_foreign_key "participant_profile_completion_date_inconsistencies", "participant_profiles"
  add_foreign_key "participant_profile_schedules", "participant_profiles"
  add_foreign_key "participant_profile_schedules", "schedules"
  add_foreign_key "participant_profile_states", "participant_profiles"
  add_foreign_key "participant_profiles", "cohorts"
  add_foreign_key "participant_profiles", "core_induction_programmes"
  add_foreign_key "participant_profiles", "participant_identities"
  add_foreign_key "participant_profiles", "participant_profiles", column: "mentor_profile_id"
  add_foreign_key "participant_profiles", "schedules"
  add_foreign_key "participant_profiles", "school_cohorts"
  add_foreign_key "participant_profiles", "schools"
  add_foreign_key "participant_profiles", "teacher_profiles"
  add_foreign_key "partnership_notification_emails", "partnerships"
  add_foreign_key "partnerships", "cohorts"
  add_foreign_key "partnerships", "delivery_partners"
  add_foreign_key "partnerships", "lead_providers"
  add_foreign_key "partnerships", "schools"
  add_foreign_key "profile_validation_decisions", "participant_profiles"
  add_foreign_key "provider_relationships", "cohorts"
  add_foreign_key "provider_relationships", "delivery_partners"
  add_foreign_key "provider_relationships", "lead_providers"
  add_foreign_key "pupil_premiums", "schools"
  add_foreign_key "schedule_milestones", "milestones"
  add_foreign_key "schedule_milestones", "schedules"
  add_foreign_key "schedules", "cohorts"
  add_foreign_key "school_cohorts", "cohorts"
  add_foreign_key "school_cohorts", "core_induction_programmes"
  add_foreign_key "school_cohorts", "induction_programmes", column: "default_induction_programme_id"
  add_foreign_key "school_cohorts", "schools"
  add_foreign_key "school_local_authorities", "local_authorities"
  add_foreign_key "school_local_authorities", "schools"
  add_foreign_key "school_local_authority_districts", "local_authority_districts"
  add_foreign_key "school_local_authority_districts", "schools"
  add_foreign_key "school_mentors", "participant_identities", column: "preferred_identity_id"
  add_foreign_key "school_mentors", "participant_profiles"
  add_foreign_key "school_mentors", "schools"
  add_foreign_key "schools", "networks"
  add_foreign_key "support_queries", "users"
  add_foreign_key "sync_dqt_induction_start_date_errors", "participant_profiles"
  add_foreign_key "teacher_profiles", "schools"
  add_foreign_key "teacher_profiles", "users"
end
