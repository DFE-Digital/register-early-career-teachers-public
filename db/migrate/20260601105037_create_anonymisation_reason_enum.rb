class CreateAnonymisationReasonEnum < ActiveRecord::Migration[8.1]
  def change
    create_enum :anonymisation_reasons, %w[registered_in_error]
  end
end
