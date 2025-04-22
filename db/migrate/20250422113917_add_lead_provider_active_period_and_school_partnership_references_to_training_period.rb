class AddLeadProviderActivePeriodAndSchoolPartnershipReferencesToTrainingPeriod < ActiveRecord::Migration[8.0]
  def change
    add_reference :training_periods, :expression_of_interest, null: true, foreign_key: { to_table: :lead_provider_active_periods }
    add_reference :training_periods, :confirmed_school_partnership, null: true, foreign_key: { to_table: :school_partnerships }
  end
end
