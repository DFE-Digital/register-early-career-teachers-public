class CreateRegion < ActiveRecord::Migration[8.0]
  def change
    create_table :regions do |t|
      t.string :code, null: false, index: { unique: true }
      t.string :districts, null: false, array: true
      t.references :teaching_school_hub, foreign_key: true

      t.timestamps
    end

    add_index :regions, :districts, using: "gin"
  end
end
