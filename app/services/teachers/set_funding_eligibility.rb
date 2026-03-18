class Teachers::SetFundingEligibility
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
    if eligible_for_ect_training?
      teacher.ect_first_became_eligible_for_training_at ||= Time.zone.now
    end

    if eligible_for_mentor_training?
      teacher.mentor_first_became_eligible_for_training_at ||= Time.zone.now
    end

    teacher.save!
  end

  def make_declarations_eligible!
    declarations_to_mark_eligible = []
    declarations_to_mark_eligible += teacher.ect_declarations.payment_status_no_payment if teacher.ect_first_became_eligible_for_training_at
    declarations_to_mark_eligible += teacher.mentor_declarations.payment_status_no_payment if teacher.mentor_first_became_eligible_for_training_at

    return unless declarations_to_mark_eligible.any?

    Declarations::Actions::MarkDeclarationsEligible.new(
      declarations: declarations_to_mark_eligible,
      author:
    ).mark
  end

  def eligible_for_ect_training?
    teacher.induction_periods.ongoing_today.any? && teacher.ect_at_school_periods.ongoing_today.any?
  end

  def eligible_for_mentor_training?
    teacher.mentor_became_ineligible_for_funding_on.blank? && teacher.mentor_became_ineligible_for_funding_reason.blank?
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
