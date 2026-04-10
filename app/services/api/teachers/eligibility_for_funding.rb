class API::Teachers::EligibilityForFunding
  attr_reader :teacher, :teacher_type

  def initialize(teacher:, teacher_type:)
    @teacher = teacher
    @teacher_type = teacher_type
  end

  def eligible?
    earliest = [eligible_on, ineligible_on].compact.min
    earliest && earliest == eligible_on
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
