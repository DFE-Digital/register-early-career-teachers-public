module TeacherHistories
  class MentorAtSchoolPeriodBuilder
    include TeacherHistories::DateExtractor
    include TeacherHistories::Indentation
    include TeacherHistories::PeriodDuration

    attr_reader :mentor_at_school_period

    def initialize(mentor_at_school_period)
      @mentor_at_school_period = mentor_at_school_period
    end

    def base_indent_level = 4

    def training_period(lead_provider, contract_period, dates, &block)
      started_on, finished_on = extract_date(dates)

      training_period = FactoryBot.build(
        :training_period,
        :for_mentor,
        mentor_at_school_period:,
        started_on:,
        finished_on:,
        **provider_data(lead_provider:, contract_period:)
      )

      if training_period.save
        print_seed_info("📗 trained by #{lead_provider.name} #{describe_period(training_period)}", indent: indent(2))
      else
        print_seed_info("Error messages: #{training_period.errors.messages}", error: true, indent: indent(2))

        fail
      end

      if block_given?
        TrainingPeriodBuilder.new(training_period).instance_eval(&block)
      end
    end

  private

    def provider_data(lead_provider:, contract_period:)
      if (school_partnership = SchoolPartnerships::Search.new(school: mentor_at_school_period.school, lead_provider:, contract_period:).school_partnerships.first)
        { school_partnership: }
      elsif (expression_of_interest = LeadProviders::Active.new(lead_provider).active_lead_providers(contract_period).first)
        { expression_of_interest: }
      end
    end
  end
end
