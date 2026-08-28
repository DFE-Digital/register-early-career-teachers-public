module Teachers
  class Overlapping
    def initialize(teacher:, other_teacher:)
      @teacher = teacher
      @other_teacher = other_teacher
    end

    def any_overlapping_periods?
      comparable_periods.any? do |periods, other_periods|
        overlapping?(periods, other_periods)
      end
    end

  private

    attr_reader :teacher, :other_teacher

    def periods_for(teacher)
      [
        teacher.mentor_at_school_periods,
        teacher.ect_at_school_periods,
        teacher.induction_periods
      ]
    end

    def comparable_periods
      periods_for(teacher).zip(periods_for(other_teacher))
    end

    def overlapping?(periods, other_periods)
      periods.to_a.product(other_periods.to_a).any? do |period, other_period|
        ordered_periods = [period, other_period].sort_by(&:started_on)

        !gap_between?(*ordered_periods)
      end
    end

    def gap_between?(period, later_period)
      return false if period.unfinished?

      period.finished_on < later_period.started_on
    end
  end
end
