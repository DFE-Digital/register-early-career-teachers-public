module TeacherHistories
  class TeacherBuilder
    ECT_COLOUR = :magenta
    MENTOR_COLOUR = :yellow

    include TeacherHistories::Indentation
    include TeacherHistories::DateExtractor
    include TeacherHistories::PeriodDuration

    attr_reader :teacher

    def initialize(teacher)
      @teacher = teacher
    end

    def base_indent_level = 2

    def self.teacher(trn, name, *factory_args, **factory_kwargs, &block)
      trs_first_name, trs_last_name = case name
                                      when Array
                                        name
                                      when String
                                        name.split(" ", 2)
                                      end

      teacher = FactoryBot.build(:teacher, *factory_args, trn:, trs_first_name:, trs_last_name:, **factory_kwargs)

      if teacher.save
        trn = teacher.trn
        full_name = Teachers::Name.new(teacher).full_name

        print_seed_info("#{full_name} - #{trn}", indent: 2)
      else
        print_seed_info("Could not create teacher #{name}", error: true, indent: indent(2))
        print_seed_info("Error messages: #{teacher.errors.messages}", error: true, indent: indent(2))

        fail
      end

      if block_given?
        TeacherHistories::TeacherBuilder.new(teacher).instance_eval(&block)
      end

      teacher
    end

    def description(text)
      print_seed_info("ℹ️ #{text}", indent: indent(2), colour: :cyan)
    end

    def induction_period(appropriate_body, dates, *factory_args, **factory_kwargs)
      term_length_in_days = (13 * 7)
      started_on, finished_on = extract_date(dates)

      number_of_terms = if finished_on.present?
                          (finished_on - started_on).to_i / term_length_in_days
                        end

      induction_period = FactoryBot.build(
        :induction_period,
        *factory_args,
        teacher:,
        appropriate_body_period: appropriate_body,
        started_on:,
        finished_on:,
        number_of_terms:,
        **factory_kwargs
      )

      if induction_period.save
        print_seed_info("🆎 induction overseen by #{appropriate_body.name} #{describe_period(induction_period)}", indent: indent(2))
      else
        print_seed_info("Error messages: #{induction_period.errors.messages}", error: true, indent: indent(2))

        fail
      end
    end

    def ect_at_school_period(school, dates, *factory_args, **factory_kwargs, &block)
      started_on, finished_on = extract_date(dates)
      ect_at_school_period = FactoryBot.build(
        :ect_at_school_period,
        :with_realistic_email_address,
        *factory_args,
        teacher:,
        school:,
        started_on:,
        finished_on:,
        **factory_kwargs
      )

      if ect_at_school_period.save
        print_seed_info("ECT at #{ect_at_school_period.school.name} #{describe_period(ect_at_school_period)}", indent: indent(2), colour: ECT_COLOUR)
      else
        print_seed_info("Error messages: #{ect_at_school_period.errors.messages}", error: true, indent: indent(2))

        fail
      end

      if block_given?
        ECTAtSchoolPeriodBuilder.new(ect_at_school_period).instance_eval(&block)
      end
    end

    def mentor_at_school_period(school, dates, *factory_args, **factory_kwargs, &block)
      started_on, finished_on = extract_date(dates)
      mentor_at_school_period = FactoryBot.build(
        :mentor_at_school_period,
        :with_realistic_email_address,
        *factory_args,
        teacher:,
        school:,
        started_on:,
        finished_on:,
        **factory_kwargs
      )

      if mentor_at_school_period.save
        print_seed_info("Mentor at #{mentor_at_school_period.school.name} #{describe_period(mentor_at_school_period)}", indent: indent(2), colour: MENTOR_COLOUR)
      else
        print_seed_info("Error messages: #{mentor_at_school_period.errors.messages}", error: true, indent: indent(2))

        fail
      end

      if block_given?
        MentorAtSchoolPeriodBuilder.new(mentor_at_school_period).instance_eval(&block)
      end
    end
  end
end
