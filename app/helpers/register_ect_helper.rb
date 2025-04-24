module RegisterECTHelper
  # @param school [School]
  def change_appropriate_body_path(school)
    return schools_register_ect_wizard_change_use_previous_ect_choices_path if school.programme_choices?
    return schools_register_ect_wizard_change_independent_school_appropriate_body_path if school.independent?

    schools_register_ect_wizard_change_state_school_appropriate_body_path
  end

  # @param school [School]
  def change_programme_type_path(school)
    return schools_register_ect_wizard_change_use_previous_ect_choices_path if school.programme_choices?

    schools_register_ect_wizard_change_programme_type_path
  end

  # @param school [School]
  def change_lead_provider_path(school)
    return schools_register_ect_wizard_change_use_previous_ect_choices_path if school.programme_choices?

    schools_register_ect_wizard_change_lead_provider_path
  end

  # @param school [School]
  def change_use_previous_ect_choices_path(school)
    return schools_register_ect_wizard_change_use_previous_ect_choices_path if school.programme_choices?

    schools_register_ect_wizard_use_previous_ect_choices
  end
end
