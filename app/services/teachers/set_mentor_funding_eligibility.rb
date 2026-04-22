class Teachers::SetMentorFundingEligibility
  attr_reader :teacher, :author

  def initialize(teacher:, author:)
    @teacher = teacher
    @author = author
  end

  def set!
    ActiveRecord::Base.transaction do
      set_eligibility!
      make_declarations_eligible!
      record_teacher_set_funding_eligibility_event!
    end
  end

private

  def set_eligibility!
    if eligible_for_mentor_training?
      teacher.mentor_first_became_eligible_for_training_at ||= Time.zone.now
    end

    teacher.save!
  end

  def make_declarations_eligible!
    return unless teacher.mentor_first_became_eligible_for_training_at

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
    return unless teacher.saved_changes?

    Events::Record.record_teacher_set_funding_eligibility_event!(
      author:,
      teacher:,
      happened_at: Time.zone.now,
      modifications: teacher.saved_changes
    )
  end
end
