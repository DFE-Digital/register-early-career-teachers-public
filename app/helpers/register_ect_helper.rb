module RegisterECTHelper
  # @param school [School]
  def change_appropriate_body_path(school)
    return schools_register_ect_wizard_change_independent_school_appropriate_body_path if school.independent?

    schools_register_ect_wizard_change_state_school_appropriate_body_path
  end

  def formatted_year_range_for_registration_date(date)
    registration_period = RegistrationPeriod.ongoing_on(date).first
    return "" if registration_period.blank?

    academic_year_string(registration_period.year)
  end

  def academic_year_string(year)
    "#{year} to #{year + 1}"
  end
end
