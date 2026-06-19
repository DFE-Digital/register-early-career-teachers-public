module TeacherHistories
  class ECTAtSchoolPeriodBuilder
    include TeacherHistories::DateExtractor
    include TeacherHistories::Indentation
    include TeacherHistories::PeriodDescription

    attr_reader :ect_at_school_period

    def initialize(ect_at_school_period)
      @ect_at_school_period = ect_at_school_period
    end

    def base_indent_level = 4

    def provider_led_training_period(lead_provider, contract_period, dates, **kwargs, &block)
      started_on, finished_on = extract_date(dates)

      provider_data = build_provider_data(lead_provider:, contract_period:)

      training_period = FactoryBot.build(
        :training_period,
        :for_ect,
        ect_at_school_period:,
        started_on:,
        finished_on:,
        **kwargs,
        **provider_data
      )

      if training_period.save
        describe_training_period(training_period)

        if ect_at_school_period.started_on == training_period.started_on
          Events::Record.record_teacher_registered_as_ect_event!(
            author:,
            school: ect_at_school_period.school,
            teacher: ect_at_school_period.teacher,
            ect_at_school_period:,
            training_period:,
            happened_at: ect_at_school_period.started_on
          )
        end

        if ect_at_school_period.finished_on == training_period.finished_on
          Events::Record.record_teacher_left_school_as_ect!(
            author:,
            school: ect_at_school_period.school,
            teacher: ect_at_school_period.teacher,
            ect_at_school_period:,
            training_period:,
            happened_at: ect_at_school_period.started_on
          )
        end
      else
        print_seed_info("Error messages: #{training_period.errors.messages}", error: true, indent: indent(2))

        fail
      end

      if block_given?
        TrainingPeriodBuilder.new(training_period).instance_eval(&block)
      end
    end

    alias_method :training_period, :provider_led_training_period

    def school_led_training_period(dates)
      started_on, finished_on = extract_date(dates)

      training_period = FactoryBot.build(
        :training_period,
        :for_ect,
        :school_led,
        ect_at_school_period:,
        started_on:,
        finished_on:
      )

      if training_period.save
        print_seed_info("🦉 received school-led training #{describe_period(training_period)}", indent: indent(2))

        if ect_at_school_period.started_on == training_period.started_on
          Events::Record.record_teacher_registered_as_ect_event!(
            author:,
            school: ect_at_school_period.school,
            teacher: ect_at_school_period.teacher,
            ect_at_school_period:,
            training_period:,
            happened_at: ect_at_school_period.started_on
          )
        end

        if ect_at_school_period.finished_on == training_period.finished_on
          Events::Record.record_teacher_left_school_as_ect!(
            author:,
            school: ect_at_school_period.school,
            teacher: ect_at_school_period.teacher,
            ect_at_school_period:,
            training_period:,
            happened_at: ect_at_school_period.started_on
          )
        end
      else
        print_seed_info("Error messages: #{training_period.errors.messages}", error: true, indent: indent(2))

        fail
      end

      if block_given?
        TrainingPeriodBuilder.new(training_period).instance_eval(&block)
      end
    end

    def mentorship_period(mentor, dates)
      mentor_at_school_period = MentorAtSchoolPeriod.find_by(teacher: mentor, school: ect_at_school_period.school)
      started_on, finished_on = extract_date(dates)

      # FIXME: we can probably do something cleverer here to work out the intersection, it might make adding
      #        mentorships a bit less tedious

      mentorship_period = FactoryBot.build(
        :mentorship_period,
        started_on:,
        finished_on:,
        mentor: mentor_at_school_period,
        mentee: ect_at_school_period
      )

      if mentorship_period.save
        mentor_name = Teachers::Name.new(mentorship_period.mentor.teacher).full_name
        print_seed_info("🌟 mentored by #{mentor_name} #{describe_period(mentorship_period)}", indent: indent(2))
      else
        print_seed_info("Error messages: #{mentorship_period.errors.messages}", error: true, indent: indent(2))

        fail
      end
    end

  private

    def build_provider_data(lead_provider:, contract_period:)
      # FIXME: could do with a bit more consistency between SchoolPartnerships::Search and LeadProviders::Active on how contract_period is
      #        used (the year vs the object)
      case
      when lead_provider == :auto
        && (school_partnership = SchoolPartnerships::Search.new(school: ect_at_school_period.school, contract_period:).school_partnerships.first)

        { school_partnership: }
      when (school_partnership = SchoolPartnerships::Search.new(school: ect_at_school_period.school, lead_provider:, contract_period:).school_partnerships.first)
        { school_partnership: }
      when (expression_of_interest = LeadProviders::Active.new(lead_provider).active_lead_providers(ContractPeriod.find(contract_period)).first)
        { expression_of_interest: }
      else
        fail "No school partnership or expression of interest found"
      end
    end

    def author
      Events::SystemAuthor.new
    end
  end
end
