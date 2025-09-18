class AddUpliftFieldsToTeachers < ActiveRecord::Migration[8.0]
  def change
    change_table :teachers, bulk: true do |t|
      t.boolean :pupil_premium_uplift, default: false, null: false
      t.boolean :sparsity_uplift, default: false, null: false
    end
  end
end
