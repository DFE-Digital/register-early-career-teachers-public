class AddInductionTutorToSchools < ActiveRecord::Migration[8.0]
  def change
    change_table :schools, bulk: true do |t|
      t.column :induction_tutor_name, :string
      t.column :induction_tutor_email, :citext
    end
  end
end
