class AddTypeToAppropriateBodies < ActiveRecord::Migration[8.0]
  def up
    rename_enum_value :appropriate_body_type, from: 'teaching_induction_panel', to: 'national'
    add_enum_value :appropriate_body_type, 'local_authority', before: 'national', if_not_exists: true

    add_column :appropriate_bodies, :type, :appropriate_body_type, default: 'teaching_school_hub'

    AppropriateBody.find_each do |appropriate_body|
      appropriate_body.update_column(:type, type_from_name(appropriate_body.name))
    end

    remove_column :ect_at_school_periods, :appropriate_body_type, :appropriate_body_type
    remove_column :schools, :chosen_appropriate_body_type, :appropriate_body_type
  end

  def down
    add_column :schools, :chosen_appropriate_body_type, :appropriate_body_type
    add_column :ect_at_school_periods, :appropriate_body_type, :appropriate_body_type

    remove_column :appropriate_bodies, :type, :appropriate_body_type

    rename_enum_value :appropriate_body_type, from: 'national', to: 'teaching_induction_panel'
  end

private

  def type_from_name(name)
    name == AppropriateBody::ISTIP ? 'national' : 'teaching_school_hub'
  end
end
