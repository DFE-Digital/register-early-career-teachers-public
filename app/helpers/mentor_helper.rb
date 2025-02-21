module MentorHelper
  # @param mentor [MentorAtSchoolPeriod]
  def link_to_mentor(mentor)
    govuk_link_to(teacher_full_name(mentor.teacher), '#', no_visited_state: true)
  end
end
