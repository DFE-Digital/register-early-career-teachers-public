module Teachers
  class Induction
    attr_reader :teacher, :induction_periods

    def initialize(teacher)
      @teacher = teacher
      @induction_periods = teacher.induction_periods
    end

    def current_induction_period
      teacher.ongoing_induction_period
    end

    def past_induction_periods
      @past_induction_periods ||= induction_periods.finished.latest_first
    end

    def induction_start_date
      @induction_start_date ||= teacher.started_induction_period&.started_on
    end

    def has_induction_periods?
      teacher.induction_periods.any?
    end

    def has_extensions?
      teacher.induction_extensions.any?
    end

    def with_appropriate_body?(appropriate_body)
      current_induction_period&.appropriate_body == appropriate_body
    end
  end
end
