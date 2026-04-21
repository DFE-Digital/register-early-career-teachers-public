module API::Teachers
  class InductionStatus
    attr_reader :teacher

    def initialize(teacher:)
      @teacher = teacher
    end

    # @return [Date, nil]
    def induction_end_date
      teacher.finished_induction_period&.finished_on || teacher.trs_induction_completed_date
    end

    # @return [Date, nil]
    def induction_start_date
      teacher.started_induction_period&.started_on || teacher.trs_induction_start_date
    end

    # @return [Boolean]
    def completed_induction?
      induction_end_date.present?
    end
  end
end
