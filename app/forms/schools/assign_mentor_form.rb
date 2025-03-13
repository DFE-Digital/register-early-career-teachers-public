module Schools
  class AssignMentorForm
    include ActiveModel::Model

    attr_accessor :ect, :mentor_id

    validates :ect, presence: { message: "ECT missing or not registered at this school" }
    validates :mentor_id, presence: { message: "Select a mentor from the list provided or choose to register a new mentor" }
    validate :mentor_at_school, if: :mentor_id
    validate :mentorship_authorized, if: -> { ect && mentor }

    def eligible_mentors
      @eligible_mentors ||= Schools::EligibleMentors.new(school).for_ect(ect).includes(:teacher)
    end

    def mentor
      @mentor ||= school.mentor_at_school_periods.find_by_id(mentor_id) if school && mentor_id
    end

    def save
      valid? && persisted?
    end

  private

    delegate :school, to: :ect, allow_nil: true

    def mentor_at_school
      errors.add(:mentor_id, "This mentor is not registered at this school") unless mentor
    end

    def mentorship_authorized
      errors.add(:mentor_id, "It needs to be a different mentor for this ECT") if eligible_mentors.exclude?(mentor)
    end

    def persisted?
      AssignMentor.new(ect:, mentor:).assign!
      true
    rescue StandardError => e
      errors.add(:base, e.to_s)
      false
    end
  end
end
