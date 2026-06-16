class AddAnonymisationFieldsToTeachers < ActiveRecord::Migration[8.1]
  def change
    change_table :teachers, bulk: true do |t|
      t.enum :anonymisation_reason, enum_type: :anonymisation_reasons, null: true
      t.datetime :anonymised_at, null: true
    end
  end
end
