class AddWrittenFailConfirmationOnToInductionPeriod < ActiveRecord::Migration[8.0]
  def change
    add_column :induction_periods, :written_fail_confirmation_on, :date
  end
end
