module TeacherHistories
  module PeriodDuration
    def describe_period(period)
      started_on = period.started_on
      finished_on = period.finished_on

      case
      when started_on.future? then "from #{started_on}"
      when finished_on.present? then "between #{started_on} and #{finished_on}"
      else "since #{started_on}"
      end
    end
  end
end
