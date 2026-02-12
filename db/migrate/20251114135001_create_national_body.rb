class CreateNationalBody < ActiveRecord::Migration[8.0]
  def change
    create_table :national_bodies do |t|
      t.string :name,
               null: false,
               index: { unique: true }

      t.references :dfe_sign_in_organisation,
                   foreign_key: true,
                   null: false,
                   index: { unique: true }

      t.timestamps
    end

    add_reference :appropriate_bodies, :national_body, foreign_key: true
  end
end
