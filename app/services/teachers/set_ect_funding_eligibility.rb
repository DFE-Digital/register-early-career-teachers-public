class Teachers::SetECTFundingEligibility
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

    teacher.save!
  end

  def make_declarations_eligible!
    return unless teacher.ect_first_became_eligible_for_training_at

    declarations = teacher.ect_declarations.payment_status_no_payment
    return unless declarations.any?

    Declarations::Actions::MarkDeclarationsEligible.new(
      declarations:,
      author:
    ).mark
  end

  def eligible_for_ect_training?
    teacher.induction_periods.ongoing_today.any? && teacher.ect_at_school_periods.any?
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
