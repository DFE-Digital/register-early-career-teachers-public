module MentorHelper
  # @param mentor [MentorAtSchoolPeriod]
  def link_to_mentor(mentor)
    govuk_link_to(teacher_full_name(mentor.teacher), schools_mentor_path(mentor))
  end
end
