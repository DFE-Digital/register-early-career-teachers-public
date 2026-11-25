class CreateLeadProviderMentorshipStatuses < ActiveRecord::Migration[8.1]
  def change
    create_enum :mentorship_statuses, %w[no-access-required access-and-support-only available-to-train]
    create_enum :mentorship_status_reasons, %w[
      mentorship-expired
      ect-finished-training-with-provider
      completed-training
      available-to-train
      mentor-training-elsewhere
      mentor-not-currently-training
      no-known-training
    ]

    create_table :lead_provider_mentorship_statuses do |t|
      t.references :mentorship_period, null: false, foreign_key: true
      t.references :lead_provider, null: false, foreign_key: true
      t.enum :status, null: false, enum_type: :mentorship_statuses
      t.enum :reason, null: false, enum_type: :mentorship_status_reasons

      t.timestamps

      t.index %i[mentorship_period_id lead_provider_id], unique: true
    end
  end
end
