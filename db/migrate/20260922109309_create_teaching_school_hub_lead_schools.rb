class CreateTeachingSchoolHubLeadSchools < ActiveRecord::Migration[8.1]
  def change
    create_table :teaching_school_hub_lead_schools do |t|
      t.references :appropriate_body, null: false, foreign_key: { to_table: :appropriate_body_periods }
      t.references :school, null: false, foreign_key: true
      t.references :region, null: false, foreign_key: true
      t.datetime :deactivated_at, null: true

      t.timestamps
    end

    # One lead school per region within an appropriate body
    add_index :teaching_school_hub_lead_schools,
              %i[appropriate_body_id region_id],
              unique: true,
              name: "index_teaching_school_hub_lead_schools_on_body_and_region"

    # A region can only be linked to one active school at a time
    add_index :teaching_school_hub_lead_schools,
              :region_id,
              unique: true,
              where: "deactivated_at IS NULL",
              name: "index_teaching_school_hub_lead_schools_on_active_region"
  end
end
