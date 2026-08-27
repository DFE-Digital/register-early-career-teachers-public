module Induction
  class TeacherInformation
    attr_reader :teacher, :induction_periods

    delegate :first_induction_period, :last_induction_period, to: :teacher

    def initialize(teacher)
      @teacher = teacher
      @induction_periods = teacher.induction_periods
    end

    # @return [String, nil]
    def induction_programme
      return unless last_induction_period

      ::INDUCTION_PROGRAMMES[last_induction_period.induction_programme.to_sym]
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

    # @return [String, nil]
    def formatted_induction_start_date
      induction_start_date&.to_fs(:govuk)
    end

    def has_induction_periods?
      teacher.induction_periods.any?
    end

    def has_extensions?
      teacher.induction_extensions.any?
    end

    # @return [String, nil]
    def appropriate_body_name
      return unless last_induction_period

      last_induction_period.appropriate_body_period.name
    end

    def with_appropriate_body?(appropriate_body_period)
      current_induction_period&.appropriate_body_period == appropriate_body_period
    end

    # @param date [Date]
    # @return [Boolean]
    def overlapping_with?(date)
      teacher.induction_periods.contains_date(date).exists?
    end

    # FIXME: this works if finished_on cannot be set to a future date
    # If that becomes possible, this query will need to be updated
    #
    # @return [InductionPeriod, nil]
    def ongoing_induction_period
      teacher.induction_periods.unfinished.first
    end
  end
end
