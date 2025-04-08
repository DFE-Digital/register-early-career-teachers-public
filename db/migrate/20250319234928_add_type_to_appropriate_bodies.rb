class AddTypeToAppropriateBodies < ActiveRecord::Migration[8.0]
  def up
    rename_enum_value :appropriate_body_type, from: 'teaching_induction_panel', to: 'national'
    add_enum_value :appropriate_body_type, 'local_authority', before: 'national', if_not_exists: true

    add_column :appropriate_bodies, :body_type, :appropriate_body_type, default: 'teaching_school_hub'

    execute <<-SQL.squish
      UPDATE appropriate_bodies
      SET body_type =
        CASE
          WHEN name = 'Independent Schools Teacher Induction Panel (ISTIP)' THEN 'national'::appropriate_body_type
          ELSE 'teaching_school_hub'::appropriate_body_type
        END
    SQL

    remove_column :ect_at_school_periods, :appropriate_body_type, :appropriate_body_type
    rename_column :ect_at_school_periods, :appropriate_body_id, :school_reported_appropriate_body_id
    remove_column :schools, :chosen_appropriate_body_type, :appropriate_body_type
  end

  def down
    add_column :schools, :chosen_appropriate_body_type, :appropriate_body_type
    rename_column :ect_at_school_periods, :school_reported_appropriate_body_id, :appropriate_body_id
    add_column :ect_at_school_periods, :appropriate_body_type, :appropriate_body_type
    remove_column :appropriate_bodies, :body_type, :appropriate_body_type

    rename_enum_value :appropriate_body_type, from: 'national', to: 'teaching_induction_panel'
  end
end
