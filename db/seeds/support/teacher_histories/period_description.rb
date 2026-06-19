module TeacherHistories
  module PeriodDescription
    def describe_period(period)
      started_on = period.started_on
      finished_on = period.finished_on

      case
      when started_on.future? then "from #{started_on}"
      when finished_on.present? then "between #{started_on} and #{finished_on}"
      else "since #{started_on}"
      end
    end

    def describe_training_period(training_period)
      if training_period.only_expression_of_interest?
        print_seed_info("📒 expression of interest registered with #{training_period.expression_of_interest_lead_provider.name} on #{training_period.started_on}", indent: indent(2))
      else
        print_seed_info("📕 trained by #{training_period.lead_provider.name} #{describe_period(training_period)}", indent: indent(2))
      end
    end
  end
end
