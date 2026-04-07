class API::Teachers::EligibilityForFunding
  attr_reader :teacher, :teacher_type

  def initialize(teacher:, teacher_type:)
    @teacher = teacher
    @teacher_type = teacher_type
  end

  def eligible?
    return nil if eligible_on.nil? && ineligible_on.nil?
    return true if eligible_on.present? && (ineligible_on.nil? || eligible_on.before?(ineligible_on))

    false
  end

private

  def eligible_on
    @eligible_on ||= if teacher_type == :ect
                       teacher.ect_first_became_eligible_for_training_at&.to_date
                     else
                       teacher.mentor_first_became_eligible_for_training_at&.to_date
                     end
  end

  def ineligible_on
    @ineligible_on ||= if teacher_type == :ect
                         teacher.ect_became_ineligible_for_funding_on
                       else
                         teacher.mentor_became_ineligible_for_funding_on
                       end
  end
end
