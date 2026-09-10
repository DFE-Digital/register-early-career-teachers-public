module Teachers
  class Overlapping
    def initialize(teacher:, other_teacher:)
      @teacher = teacher
      @other_teacher = other_teacher
    end

    def any_overlapping_periods?
      overlapping_induction_periods? ||
        overlapping_mentor_at_school_periods? ||
        overlapping_ect_at_school_periods?
    end

  private

    attr_reader :teacher, :other_teacher

    def overlapping_induction_periods?
      overlapping?(teacher.induction_periods, other_teacher.induction_periods)
    end

    def overlapping_mentor_at_school_periods?
      overlapping?(teacher.mentor_at_school_periods, other_teacher.mentor_at_school_periods)
    end

    def overlapping_ect_at_school_periods?
      overlapping?(teacher.ect_at_school_periods, other_teacher.ect_at_school_periods)
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
