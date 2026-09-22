class CreateTeachingSchoolHubs < ActiveRecord::Migration[8.0]
  def change
    create_table :teaching_school_hubs do |t|
      t.string :name, null: false, index: { unique: true }

      t.timestamps
    end
  end
end
