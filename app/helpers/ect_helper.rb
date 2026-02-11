module ECTHelper
  # @param ect [ECTAtSchoolPeriod]
  def current_mentor_name(ect)
    ECTAtSchoolPeriods::Mentorship.new(ect).current_mentor_name
  end

  # @param ect [ECTAtSchoolPeriod]
  def latest_delivery_partner_name(ect)
    ECTAtSchoolPeriods::CurrentTraining.new(ect).delivery_partner_name || "Their lead provider will confirm this"
  end

  # @param ect [ECTAtSchoolPeriod]
  def latest_lead_provider_name(ect)
    ECTAtSchoolPeriods::CurrentTraining.new(ect).lead_provider_name
  end

  # @param ect [ECTAtSchoolPeriod]
  def latest_mentor_name(ect)
    ECTAtSchoolPeriods::Mentorship.new(ect).latest_mentor_name
  end

  # @param ect [ECTAtSchoolPeriod]
  def latest_eoi_lead_provider_name(ect)
    ECTAtSchoolPeriods::CurrentTraining.new(ect).expression_of_interest_lead_provider_name
  end

  # @param ect [ECTAtSchoolPeriod]
  def link_to_assign_mentor(ect)
    govuk_warning_text(text: assign_or_create_mentor_link(ect))
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
    mentorship = ECTAtSchoolPeriods::Mentorship.new(ect)

    if mentorship && mentorship.current_mentor.present?
      govuk_link_to(mentorship.current_mentor_name, schools_mentor_path(mentorship.current_mentor))
    else
      link_to_assign_mentor(ect)
    end
  end

  # @param ect [ECTAtSchoolPeriod]
  def mentor_required?(ect, current_school: nil)
    return false if current_school && ect.leaving_reported_for_school?(current_school)

    induction_status = ect.teacher.trs_induction_status
    return false if induction_status.in?(%w[Passed Failed Exempt])

    current_mentor_name(ect).blank?
  end

  # @param ect [ECTAtSchoolPeriod]
  def ect_status(ect, current_school: nil)
    return govuk_tag(text: "Leaving school", colour: "yellow") if current_school && ect.leaving_reported_for_school?(current_school)

    induction_status = ect.teacher.trs_induction_status

    case induction_status
    when "Passed"
      govuk_tag(text: "Completed induction", colour: "blue")
    when "Failed"
      govuk_tag(text: "Failed induction", colour: "pink")
    when "Exempt"
      govuk_tag(text: "Exempt", colour: "grey")
    else
      if current_mentor_name(ect)
        govuk_tag(text: "Registered", colour: "green")
      else
        govuk_tag(text: "Mentor required", colour: "red")
      end
    end
  end

  def register_mentor_back_link(ect, new_mentor_requested)
    return schools_ects_change_mentor_wizard_edit_path(ect, new_mentor_requested: true) if new_mentor_requested

    if eligible_mentors_for_ect?(ect)
      new_schools_ect_mentorship_path(ect)
    else
      schools_ects_home_path
    end
  end

  # @param ect [ECTAtSchoolPeriod]
  def training_lead_provider_name_for_display(ect)
    training_period = training_period_for_display(ect)
    return if training_period.blank?

    if training_period.only_expression_of_interest?
      training_period.expression_of_interest&.lead_provider&.name
    else
      training_period.school_partnership
        &.lead_provider_delivery_partnership
        &.active_lead_provider
        &.lead_provider
        &.name
    end
  end

  # @param ect [ECTAtSchoolPeriod]
  def training_delivery_partner_name_for_display(ect)
    training_period = training_period_for_display(ect)
    return if training_period.blank?
    return if training_period.only_expression_of_interest?

    training_period.school_partnership
      &.lead_provider_delivery_partnership
      &.delivery_partner
      &.name
  end

  # @param ect [ECTAtSchoolPeriod]
  def training_delivery_partner_text_for_display(ect)
    training_period = training_period_for_display(ect)
    return if training_period.blank?

    if training_period.only_expression_of_interest?
      "Their lead provider will confirm this"
    else
      training_delivery_partner_name_for_display(ect)
    end
  end

private

  def assign_or_create_mentor_link(ect)
    govuk_link_to("Assign a mentor for this ECT", assign_or_create_mentor_path(ect), no_visited_state: true)
  end

  def assign_or_create_mentor_path(ect)
    return new_schools_ect_mentorship_path(ect) if eligible_mentors_for_ect?(ect)

    schools_register_mentor_wizard_start_path(ect_id: ect.id)
  end

  def eligible_mentors_for_ect?(ect)
    Schools::EligibleMentors.new(ect.school).for_ect(ect).exists?
  end

  def training_period_for_display(ect)
    Schools::ECTTrainingPresenter.new(ect).training_period_for_display
  end
end
