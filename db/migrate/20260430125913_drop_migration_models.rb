class DropMigrationModels < ActiveRecord::Migration[8.1]
  def change
    drop_table "migration_failures" do |t|
      t.datetime "created_at", null: false
      t.bigint "data_migration_id", null: false
      t.string "failure_message"
      t.json "item", null: false
      t.string "migration_mode"
      t.integer "parent_id"
      t.string "parent_type"
      t.datetime "updated_at", null: false
      t.index %w[data_migration_id], name: "index_migration_failures_on_data_migration_id"
      t.index %w[parent_id], name: "index_migration_failures_on_parent_id"
    end

    drop_table "teacher_migration_failures" do |t|
      t.datetime "created_at", null: false
      t.string "message", null: false
      t.uuid "migration_item_id"
      t.string "migration_item_type"
      t.string "migration_mode"
      t.string "model", default: "teacher", null: false
      t.bigint "teacher_id"
      t.datetime "updated_at", null: false
      t.index %w[model], name: "index_teacher_migration_failures_on_model"
      t.index %w[teacher_id], name: "index_teacher_migration_failures_on_teacher_id"
    end

    drop_table "data_migration_failed_combinations" do |t|
      t.integer "cohort_year"
      t.datetime "created_at", null: false
      t.string "delivery_partner_name"
      t.datetime "end_date"
      t.text "failure_message"
      t.uuid "induction_record_id"
      t.string "induction_status"
      t.string "lead_provider_name"
      t.uuid "mentor_profile_id"
      t.string "migration_mode"
      t.string "preferred_identity_email"
      t.uuid "profile_id"
      t.string "profile_type"
      t.integer "schedule_cohort_year"
      t.uuid "schedule_id"
      t.string "schedule_identifier"
      t.string "schedule_name"
      t.string "school_urn"
      t.datetime "start_date"
      t.string "training_programme"
      t.string "training_status"
      t.string "trn"
      t.datetime "updated_at", null: false
    end

    drop_table "data_migration_failed_mentorships" do |t|
      t.datetime "created_at", null: false
      t.uuid "ecf_end_induction_record_id"
      t.uuid "ecf_start_induction_record_id"
      t.uuid "ect_participant_profile_id"
      t.text "failure_message"
      t.date "finished_on"
      t.uuid "mentor_participant_profile_id"
      t.string "migration_mode"
      t.date "started_on"
      t.datetime "updated_at", null: false
    end

    drop_table "data_migration_teacher_combinations" do |t|
      t.uuid "api_id"
      t.datetime "created_at", null: false
      t.jsonb "ecf1_ect_combinations", default: [], null: false
      t.virtual "ecf1_ect_combinations_count", type: :integer, as: "jsonb_array_length(ecf1_ect_combinations)", stored: true
      t.uuid "ecf1_ect_profile_id"
      t.jsonb "ecf1_mentor_combinations", default: [], null: false
      t.virtual "ecf1_mentor_combinations_count", type: :integer, as: "jsonb_array_length(ecf1_mentor_combinations)", stored: true
      t.uuid "ecf1_mentor_profile_id"
      t.jsonb "ecf1_mentorships", default: [], null: false
      t.virtual "ecf1_mentorships_count", type: :integer, as: "jsonb_array_length(ecf1_mentorships)", stored: true
      t.jsonb "ecf2_ect_combinations", default: [], null: false
      t.virtual "ecf2_ect_combinations_count", type: :integer, as: "jsonb_array_length(ecf2_ect_combinations)", stored: true
      t.jsonb "ecf2_mentor_combinations", default: [], null: false
      t.virtual "ecf2_mentor_combinations_count", type: :integer, as: "jsonb_array_length(ecf2_mentor_combinations)", stored: true
      t.jsonb "ecf2_mentorships", default: [], null: false
      t.virtual "ecf2_mentorships_count", type: :integer, as: "jsonb_array_length(ecf2_mentorships)", stored: true
      t.string "migration_mode"
      t.datetime "updated_at", null: false
    end

    drop_table "data_migrations" do |t|
      t.json "cache_stats"
      t.datetime "completed_at"
      t.datetime "created_at", null: false
      t.integer "failure_count", default: 0, null: false
      t.string "model", null: false
      t.integer "processed_count", default: 0, null: false
      t.datetime "queued_at"
      t.datetime "started_at"
      t.integer "total_count"
      t.datetime "updated_at", null: false
      t.integer "worker"
    end
  end
end
