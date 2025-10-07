class Teachers::SetFundingEligibilty
  attr_reader :teacher, :author

  def initialize(teacher:, author:)
    @teacher = teacher
    @author = author
  end

  def set!
    ActiveRecord::Base.transaction do
      set_eligibility!
      record_teacher_set_funding_eligibilty_event!
    end
  end

private

  def set_eligibility!
    if eligible_for_ect_training?
      teacher.first_became_eligible_for_ect_training_at ||= Time.zone.now
    end

    if eligible_for_mentor_training?
      teacher.first_became_eligible_for_mentor_training_at ||= Time.zone.now
    end

    teacher.save!
  end

  def eligible_for_ect_training?
    teacher.induction_periods.ongoing_today.any? && teacher.ect_at_school_periods.ongoing_today.any?
  end

  def eligible_for_mentor_training?
    teacher.mentor_became_ineligible_for_funding_on.blank? && teacher.mentor_became_ineligible_for_funding_reason.blank?
  end

  def record_teacher_set_funding_eligibilty_event!
    return unless teacher.saved_changes?

    Events::Record.record_teacher_set_funding_eligibilty_event!(
      author:,
      teacher:,
      happened_at: Time.zone.now,
      modifications: teacher.saved_changes
    )
  end
end
