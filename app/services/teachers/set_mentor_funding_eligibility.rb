class Teachers::SetMentorFundingEligibility
  attr_reader :teacher, :author

  def initialize(teacher:, author:)
    @teacher = teacher
    @author = author
  end

  def set!
    ActiveRecord::Base.transaction do
      set_eligibility!
    end
  end

private

  def set_eligibility!
    return unless eligible_for_mentor_training?
    return if teacher.mentor_first_became_eligible_for_training_at

    teacher.touch(:mentor_first_became_eligible_for_training_at)

    make_declarations_eligible!
    record_teacher_set_funding_eligibility_event!
  end

  def make_declarations_eligible!
    declarations = teacher.mentor_declarations.payment_status_no_payment
    return unless declarations.any?

    Declarations::Actions::MarkDeclarationsEligible.new(
      declarations:,
      author:
    ).mark
  end

  def eligible_for_mentor_training?
    teacher.mentor_training_periods.any? &&
      teacher.mentor_became_ineligible_for_funding_on.blank? &&
      teacher.mentor_became_ineligible_for_funding_reason.blank?
  end

  def record_teacher_set_funding_eligibility_event!
    Events::Record.record_teacher_set_funding_eligibility_event!(
      author:,
      teacher:,
      teacher_type: "Mentor",
      happened_at: Time.zone.now,
      modifications: teacher.saved_changes
    )
  end
end
