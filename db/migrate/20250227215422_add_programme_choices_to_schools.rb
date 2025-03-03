class AddProgrammeChoicesToSchools < ActiveRecord::Migration[8.0]
  def change
    create_enum :appropriate_body_type, %w[teaching_induction_panel teaching_school_hub]
    create_enum :programme_type, %w[provider_led school_led]

    add_column :ect_at_school_periods, :appropriate_body_type, :appropriate_body_type
    add_column :schools, :chosen_appropriate_body_type, :appropriate_body_type
    add_reference :schools, :chosen_appropriate_body, foreign_key: { to_table: :appropriate_bodies }
    add_reference :schools, :chosen_lead_provider, foreign_key: { to_table: :lead_providers }
    add_column :schools, :chosen_programme_type, :programme_type
  end
end
