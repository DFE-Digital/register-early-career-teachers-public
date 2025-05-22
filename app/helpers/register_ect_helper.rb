module RegisterECTHelper
  # @param school [School]
  def change_appropriate_body_path(school)
    return schools_register_ect_wizard_change_independent_school_appropriate_body_path if school.independent?

    schools_register_ect_wizard_change_state_school_appropriate_body_path
  end

  def formatted_academic_year_range(year)
    "#{year} to #{year + 1}"
  end
end
