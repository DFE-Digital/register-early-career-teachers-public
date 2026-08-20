class RemoveTRSFlagsFromTeachers < ActiveRecord::Migration[8.1]
  def change
    change_table :teachers, bulk: true do |t|
      t.remove :trs_deactivated, type: :boolean, default: false
      t.remove :trs_not_found, type: :boolean, default: false
    end
  end
end
