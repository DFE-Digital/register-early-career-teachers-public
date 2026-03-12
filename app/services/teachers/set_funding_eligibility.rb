class Teachers::SetFundingEligibility
  attr_reader :teacher, :author

  def initialize(teacher:, author:)
    @teacher = teacher
    @author = author
  end

  def set!
    ActiveRecord::Base.transaction do
      grab_current_eligibility
      set_eligibility!
      make_declarations_eligible!
      record_teacher_set_funding_eligibility_event!
    end
  end

private

  def grab_current_eligibility
    @previous_ect_first_became_eligible_for_training_at = teacher.ect_first_became_eligible_for_training_at
    @previous_mentor_first_became_eligible_for_training_at = teacher.mentor_first_became_eligible_for_training_at
  end

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
    declaration_ids_to_make_eligible = []

    if @previous_ect_first_became_eligible_for_training_at.nil? && teacher.ect_first_became_eligible_for_training_at.present?
      declaration_ids_to_make_eligible.concat(teacher.ect_declarations.ids)
    end

    if @previous_mentor_first_became_eligible_for_training_at.nil? && teacher.mentor_first_became_eligible_for_training_at.present?
      declaration_ids_to_make_eligible.concat(teacher.mentor_declarations.ids)
    end

    return unless declaration_ids_to_make_eligible.any?

    Declarations::Actions::MarkDeclarationsEligible.new(
      declarations: Declaration.where(id: declaration_ids_to_make_eligible.uniq),
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
