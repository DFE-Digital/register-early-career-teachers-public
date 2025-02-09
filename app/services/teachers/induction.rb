module Teachers
  class Induction
    attr_reader :teacher

    def initialize(teacher)
      @teacher = teacher
    end

    def current_induction_period
      @current_induction_period ||= teacher.induction_periods.ongoing.first
    end

    def past_induction_periods
      @past_induction_periods ||= teacher.induction_periods.where.not(finished_on: nil).order(finished_on: :desc)
    end

    def induction_start_date
      @induction_start_date ||= teacher.induction_periods.order(:started_on).first&.started_on
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
