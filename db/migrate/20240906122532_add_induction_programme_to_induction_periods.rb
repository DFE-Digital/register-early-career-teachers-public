class AddInductionProgrammeToInductionPeriods < ActiveRecord::Migration[7.2]
  def change
    create_enum :induction_programme, %w[cip fip diy]

    change_table :induction_periods do |t|
      t.enum :induction_programme, null: false, enum_type: :induction_programme
      t.integer :number_of_terms, null: true
    end
  end
end
