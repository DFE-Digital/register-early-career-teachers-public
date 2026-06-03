class AddArchiveFieldsToTeachers < ActiveRecord::Migration[8.1]
  def change
    change_table :teachers, bulk: true do |t|
      t.enum :archived_reason, enum_type: :archived_reasons, null: true
      t.datetime :archived_at, null: true
    end
  end
end
