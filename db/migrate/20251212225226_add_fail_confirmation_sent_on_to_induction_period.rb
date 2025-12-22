class AddFailConfirmationSentOnToInductionPeriod < ActiveRecord::Migration[8.0]
  def change
    add_column :induction_periods, :fail_confirmation_sent_on, :date
  end
end
