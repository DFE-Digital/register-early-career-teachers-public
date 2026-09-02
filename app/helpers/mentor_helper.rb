module MentorHelper
  # @param mentor [MentorAtSchoolPeriod]
  def link_to_mentor(mentor)
    govuk_link_to(teacher_full_name(mentor.teacher), schools_mentor_path(mentor))
  end

  def assign_existing_mentor_lead_provider_back_link(wizard)
    if wizard.context.ect_lead_provider_available?
      schools_assign_existing_mentor_wizard_review_mentor_eligibility_path
    else
      new_schools_ect_mentorship_path(wizard.context.ect_at_school_period, preselect: wizard.mentor_period_id)
    end
  end
end
