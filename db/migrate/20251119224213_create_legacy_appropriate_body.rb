class CreateLegacyAppropriateBody < ActiveRecord::Migration[8.0]
  def change
    create_table :legacy_appropriate_bodies do |t|
      t.uuid :dqt_id,
             null: false,
             index: { unique: true }

      t.string :name,
               null: false,
               index: { unique: true }

      t.enum :body_type,
             enum_type: :appropriate_body_type,
             null: false

      t.references :appropriate_body_period,
                   foreign_key: {
                     to_table: :appropriate_bodies
                   },
                   null: false,
                   index: { unique: true }

      t.timestamps
    end
  end
end
