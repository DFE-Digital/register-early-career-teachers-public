class AddProgrammeChoicesToSchools < ActiveRecord::Migration[8.0]
  def change
    create_enum :appropriate_body_type, %w[teaching_induction_panel teaching_school_hub]
    create_enum :programme_type, %w[provider_led school_led]

    reversible do |dir|
      dir.up do
        change_column :ect_at_school_periods, :programme_type, :programme_type, using: "programme_type::programme_type"
      end
      dir.down do
        change_column :ect_at_school_periods, :programme_type, :string
      end
    end

    add_column :ect_at_school_periods, :appropriate_body_type, :appropriate_body_type
    add_column :schools, :chosen_appropriate_body_type, :appropriate_body_type
    add_reference :schools, :chosen_appropriate_body, foreign_key: { to_table: :appropriate_bodies }
    add_reference :schools, :chosen_lead_provider, foreign_key: { to_table: :lead_providers }
    add_column :schools, :chosen_programme_type, :programme_type

    ECTAtSchoolPeriod.find_each do |ect|
      if ect.school.state?
        raise('appropriate body must be set') if ect.appropriate_body_id.nil?

        ect.update_column(:appropriate_body_type, 'teaching_school_hub')
      else
        ect.update_column(:appropriate_body_type, ect.appropriate_body_id.present? ? 'teaching_school_hub' : 'teaching_induction_panel')
      end

      raise("Lead provider must not be set") if ect.school_led_programme_type? && ect.lead_provider_id
    end
  end
end
