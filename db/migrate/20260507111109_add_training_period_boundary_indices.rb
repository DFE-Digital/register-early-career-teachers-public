class AddTrainingPeriodBoundaryIndices < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # Optimise API school transfer queries
  def change
    add_index :training_periods,
              %i[api_transfer_updated_at ect_at_school_period_id],
              name: :idx_training_periods_transfer_updated_ect,
              where: "ect_at_school_period_id IS NOT NULL"

    add_index :training_periods,
              %i[api_transfer_updated_at mentor_at_school_period_id],
              name: :idx_training_periods_transfer_updated_mentor,
              where: "mentor_at_school_period_id IS NOT NULL"

    add_index :training_periods,
              %i[ect_at_school_period_id started_on],
              name: :idx_training_periods_ect_started_on

    add_index :training_periods,
              %i[mentor_at_school_period_id started_on],
              name: :idx_training_periods_mentor_started_on

    add_index :training_periods,
              %i[api_transfer_updated_at school_partnership_id],
              name: :idx_training_periods_transfer_updated_partnership

    add_index :lead_provider_delivery_partnerships,
              [:active_lead_provider_id],
              name: :idx_lpdps_active_lead_provider
  end
end
