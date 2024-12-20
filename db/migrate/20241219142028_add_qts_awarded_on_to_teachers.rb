class AddQtsAwardedOnToTeachers < ActiveRecord::Migration[8.0]
  def change
    add_column :teachers, :qts_awarded_on, :date
  end
end
