class ConsolidateAppropriateBodies < ActiveRecord::Migration[8.0]
  def change
    remove_reference :appropriate_body_periods, :teaching_school_hub, index: true, foreign_key: true
    remove_reference :appropriate_body_periods, :national_body, index: true, foreign_key: true
    remove_reference :appropriate_body_periods, :lead_school, index: true, foreign_key: { to_table: :schools }

    remove_reference :regions, :teaching_school_hub, index: true

    drop_table :teaching_school_hubs do |t|
      t.string :name,
               null: false

      t.references :lead_school,
                   foreign_key: { to_table: :schools },
                   null: false,
                   index: true

      t.references :dfe_sign_in_organisation,
                   foreign_key: true,
                   null: false,
                   index: true

      t.timestamps
    end

    drop_table :national_bodies do |t|
      t.string :name,
               null: false,
               index: { unique: true }

      t.references :dfe_sign_in_organisation,
                   foreign_key: true,
                   null: false,
                   index: { unique: true }

      t.timestamps
    end

    create_table :appropriate_bodies do |t|
      t.string :name,
               null: false

      t.references :dfe_sign_in_organisation,
                   foreign_key: true,
                   null: false,
                   index: true

      t.timestamps
    end

    add_reference :appropriate_body_periods, :appropriate_body, index: true, foreign_key: true
    add_reference :regions, :appropriate_body, foreign_key: true, index: true
  end
end
