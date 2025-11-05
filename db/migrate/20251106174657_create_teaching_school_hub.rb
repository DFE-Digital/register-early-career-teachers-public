class CreateTeachingSchoolHub < ActiveRecord::Migration[8.0]
  def change
    create_table :teaching_school_hubs do |t|
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

    add_reference :appropriate_bodies, :teaching_school_hub, foreign_key: true
    add_reference :appropriate_bodies, :lead_school, foreign_key: { to_table: :schools }
  end
end
