class AddExpressionOfInterestRelationshipToTrainingPeriod < ActiveRecord::Migration[8.0]
  def change
    add_reference :training_periods, :expression_of_interest, foreign_key: { to_table: :active_lead_providers }
  end
end
