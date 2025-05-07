class AddExpressionOfInterestReferenceToTrainingPeriod < ActiveRecord::Migration[8.0]
  def change
    add_reference :training_periods, :expression_of_interest, null: true, foreign_key: { to_table: :lead_provider_active_periods }
    change_column_null :training_periods, :school_partnership_id, true
  end
end
