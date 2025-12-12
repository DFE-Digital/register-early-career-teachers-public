class CreateRegion < ActiveRecord::Migration[8.0]
  def change
    create_table :regions do |t|
      t.string :code, null: false, index: { unique: true }
      t.string :districts, null: false

      t.timestamps
    end
  end
end
