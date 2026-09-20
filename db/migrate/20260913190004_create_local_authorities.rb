class CreateLocalAuthorities < ActiveRecord::Migration[8.0]
  def change
    create_table :local_authorities do |t|
      t.string :name, null: false, index: { unique: true }

      t.timestamps
    end
  end
end
