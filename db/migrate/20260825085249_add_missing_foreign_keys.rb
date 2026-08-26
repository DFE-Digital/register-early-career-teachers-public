class AddMissingForeignKeys < ActiveRecord::Migration[8.0]
  def change
    # A number of mentorship periods were removed recently as part of a data clean up.
    # This left some declarations with mentorship_period_id values that no longer exist in the mentorship_periods table.
    # We need to set those mentorship_period_id values to nil before we can add the foreign key constraint.
    Declaration
      .where.not(mentorship_period_id: nil)
      .where.not(mentorship_period_id: MentorshipPeriod.select(:id))
      .update_all(mentorship_period_id: nil)

    add_foreign_key :api_tokens, :lead_providers

    add_foreign_key :lead_provider_delivery_partnerships, :framework_agreements
    add_foreign_key :lead_provider_delivery_partnerships, :delivery_partners

    add_foreign_key :school_partnerships, :lead_provider_delivery_partnerships

    # These two tables have a lot more rows, so we add constraints without validating
    # existing rows to minimise write-blocking locks, then validate separately
    # which uses a less restrictive lock.
    add_foreign_key :declarations, :mentorship_periods, validate: false
    add_foreign_key :metadata_teachers_lead_providers,
                    :mentor_at_school_periods,
                    column: :ect_assigned_mentor_latest_school_period_id,
                    validate: false

    validate_foreign_key :declarations, :mentorship_periods
    validate_foreign_key :metadata_teachers_lead_providers,
                         :mentor_at_school_periods,
                         column: :ect_assigned_mentor_latest_school_period_id
  end
end
