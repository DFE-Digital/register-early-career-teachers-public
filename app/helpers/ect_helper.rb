module ECTHelper
  # @param ect [ECTAtSchoolPeriod]
  def link_to_assign_mentor(ect)
    govuk_warning_text(text: "You must #{assign_or_create_mentor_link(ect)} for this ECT.".html_safe)
  end

  # @param ect [ECTAtSchoolPeriod]
  def link_to_ect(ect)
    govuk_link_to(teacher_full_name(ect.teacher), schools_ect_path(ect), no_visited_state: true)
  end

  # @param ect [ECTAtSchoolPeriod]
  def ect_start_date(ect)
    date_as_hash = { 1 => ect.started_on.year, 2 => ect.started_on.month, 3 => ect.started_on.day }
    Schools::Validation::ECTStartDate.new(date_as_hash:).formatted_date
  end

  # @param ect [ECTAtSchoolPeriod]
  def ect_mentor_details(ect)
    if ect.current_mentor.present?
      teacher_full_name(ect.current_mentor.teacher)
    else
      link_to_assign_mentor(ect)
    end
  end

  # TODO: was something planned in Schools::Teacher?
  def ect_status(_ect)
    govuk_tag(text: 'In progress', colour: 'green')
  end

private

  def assign_or_create_mentor_link(ect)
    govuk_link_to("assign a mentor or register a new one", assign_or_create_mentor_path(ect), no_visited_state: true)
  end

  def assign_or_create_mentor_path(ect)
    return new_schools_ect_mentorship_path(ect) if eligible_mentors_for_ect?(ect)

    schools_register_mentor_wizard_start_path(ect_id: ect.id)
  end

  def eligible_mentors_for_ect?(ect)
    Schools::EligibleMentors.new(ect.school).for_ect(ect).exists?
  end
end
