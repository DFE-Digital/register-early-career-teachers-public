module APISeedData
  class TeachersWithHistories < Base
    NUMBER_OF_RECORDS = 250

    TRAINING_STATUS_COLOURS = {
      active: :green,
      withdrawn: :red,
      deferred: :yellow,
    }.freeze

    ECT_MENTOR_RATIO = 0.5
    ECT_INDUCTION_RATIO = 0.85
    SCHEDULE_RATIO = 0.8
    WITHDRAWN_RATIO = 0.2
    DEFERRED_RATIO = 0.15
    ECT_MENTOR_SCHOOL_PERIOD_TRAIT_RATIO = 0.1
    ECT_SPECIFIC_TRAIT_RATIO = 0.1
    OPTIONAL_MENTOR_TRAINING_RATIO = 0.1
    OPTIONAL_ECT_TRAINING_RATIO = 0.1
    ECT_ELIGIBLE_FOR_TRAINING_RATIO = 0.65
    PUPIL_PREMIUM_UPLIFT_RATIO = 0.15
    SPARSITY_UPLIFT_RATIO = 0.20
    MENTOR_ELIGIBLE_FOR_TRAINING_RATIO = 0.65
    TEACHER_ID_CHANGE_RATIO = 0.15
    ASSIGN_ECT_TO_MENTOR_RATIO = 0.20
    LATE_START_RATIO = 0.05
    FINISHED_PERIOD_RATIO = 0.7

    def plant
      return unless plantable?

      log_plant_info("api teachers with histories")

      groups_of_active_lead_providers.each_value do |grouped_active_lead_providers|
        grouped_active_lead_providers.each do |active_lead_provider|
          (NUMBER_OF_RECORDS / grouped_active_lead_providers.size).times do
            create_api_teachers_records_for(active_lead_provider)
          end
        end
      end
    end

  protected

    def plantable?
      super && TrainingPeriod.none?
    end

  private

    def create_teacher(started_on:)
      # Randomize created at time
      created_at = started_on.to_time + rand(60 * 23).minutes

      teacher = FactoryBot.create(
        :teacher,
        :with_realistic_name,
        trn: Helpers::TRNGenerator.next
      ).tap do |t|
        t.update!(
          created_at:,
          updated_at: created_at,
          api_updated_at: created_at
        )
      end

      log_seed_info(::Teachers::Name.new(teacher).full_name, indent: 2)
      teacher
    end

    def groups_of_active_lead_providers
      ActiveLeadProvider.all.group_by(&:lead_provider_id)
    end

    def create_api_teachers_records_for(active_lead_provider)
      contract_period = active_lead_provider.contract_period
      school_partnership = find_school_partnership(active_lead_provider)
      return if school_partnership.blank?

      school = school_partnership.school

      school_period = random_period(contract_period:)
      teacher = create_teacher(started_on: school_period[:started_on])

      training_period_data = random_period_within(**school_period)
      training_period_traits = if training_period_data[:started_on].future?
                                 []
                               else
                                 generate_training_period_traits
                               end
      ect_mentor_traits = generate_ect_mentor_school_period_traits
      ect_specific_traits = generate_ect_specific_traits
      schedule = find_schedule(school_partnership.contract_period)

      if rand_boolean(ECT_MENTOR_RATIO)
        create_ect_and_optional_mentor_training(
          teacher,
          school,
          school_period,
          schedule,
          school_partnership,
          training_period_data,
          training_period_traits,
          ect_mentor_traits,
          ect_specific_traits
        )

        create_induction_period(teacher:)
      else
        create_mentor_and_optional_ect_training(
          teacher,
          school,
          school_period,
          schedule,
          school_partnership,
          training_period_data,
          training_period_traits,
          ect_mentor_traits,
          ect_specific_traits
        )
      end
    end

    def find_school_partnership(active_lead_provider)
      SchoolPartnership
        .joins(:lead_provider_delivery_partnership)
        .where(lead_provider_delivery_partnership: { active_lead_provider: })
        .order(Arel.sql("RANDOM()"))
        .first
    end

    def find_schedule(contract_period)
      if rand_boolean(SCHEDULE_RATIO)
        return Schedule.find_by(
          contract_period:,
          identifier: "ecf-standard-september"
        )
      end

      Schedule
        .excluding_replacement_schedules
        .where(contract_period:)
        .order(Arel.sql("RANDOM()"))
        .first
    end

    def generate_training_period_traits
      [].tap do |traits|
        if rand_boolean(WITHDRAWN_RATIO)
          traits << :withdrawn
        elsif rand_boolean(DEFERRED_RATIO)
          traits << :deferred
        end
      end
    end

    def generate_ect_mentor_school_period_traits
      [].tap do |traits|
        traits << :with_teacher_payments_frozen_year if rand_boolean(ECT_MENTOR_SCHOOL_PERIOD_TRAIT_RATIO)
      end
    end

    def generate_ect_specific_traits
      [].tap do |traits|
        traits << :with_teacher_payments_frozen_year if rand_boolean(ECT_SPECIFIC_TRAIT_RATIO)
      end
    end

    def create_ect_and_optional_mentor_training(
      teacher,
      school,
      school_period,
      schedule,
      school_partnership,
      training_period_data,
      training_period_traits,
      ect_mentor_traits,
      ect_specific_traits
    )
      ect_at_school_period_record = ect_at_school_period(
        teacher:,
        school:,
        school_period:,
        traits: ect_mentor_traits + ect_specific_traits
      )

      FactoryBot.create(
        :training_period,
        *training_period_traits.compact,
        :with_schedule,
        :for_ect,
        schedule:,
        ect_at_school_period: ect_at_school_period_record,
        school_partnership:,
        **training_period_data
      ).tap { |tp| log_training_period(training_period: tp) }

      set_ect_attributes(teacher:)
      create_teacher_id_change_for(teacher:)

      if rand_boolean(OPTIONAL_MENTOR_TRAINING_RATIO)
        mentor_at_school_period_record = mentor_at_school_period(
          teacher:,
          school:,
          school_period:,
          traits: ect_mentor_traits
        )

        FactoryBot.create(
          :training_period,
          *training_period_traits.compact,
          :with_schedule,
          :for_mentor,
          schedule:,
          mentor_at_school_period: mentor_at_school_period_record,
          school_partnership:,
          **training_period_data
        ).tap { |tp| log_training_period(training_period: tp) }
      end
    end

    def create_mentor_and_optional_ect_training(
      teacher,
      school,
      school_period,
      schedule,
      school_partnership,
      training_period_data,
      training_period_traits,
      ect_mentor_traits,
      ect_specific_traits
    )
      mentor_at_school_period_record = mentor_at_school_period(
        teacher:,
        school:,
        school_period:,
        traits: ect_mentor_traits
      )

      FactoryBot.create(
        :training_period,
        *training_period_traits.compact,
        :with_schedule,
        :for_mentor,
        schedule:,
        mentor_at_school_period: mentor_at_school_period_record,
        school_partnership:,
        **training_period_data
      ).tap { |tp| log_training_period(training_period: tp) }

      set_mentor_attributes(teacher:)
      create_teacher_id_change_for(teacher:)

      if rand_boolean(OPTIONAL_ECT_TRAINING_RATIO)
        ect_at_school_period_record = ect_at_school_period(
          teacher:,
          school:,
          school_period:,
          traits: ect_mentor_traits + ect_specific_traits
        )

        FactoryBot.create(
          :training_period,
          *training_period_traits.compact,
          :with_schedule,
          :for_ect,
          schedule:,
          ect_at_school_period: ect_at_school_period_record,
          school_partnership:,
          **training_period_data
        ).tap { |tp| log_training_period(training_period: tp) }
      end

      assign_ect_to_mentor(teacher:, school:, mentor_at_school_period_record:)
    end

    def ect_at_school_period(teacher:, school:, school_period:, traits:)
      email = Faker::Internet.email(name: ::Teachers::Name.new(teacher).full_name)
      school_reported_appropriate_body = random_appropriate_body

      FactoryBot.create(
        :ect_at_school_period,
        *traits.compact,
        teacher:,
        school:,
        email:,
        school_reported_appropriate_body:,
        created_at: teacher.created_at,
        **school_period
      ).tap { |easp| log_ect_at_school_period(ect_at_school_period: easp) }
    end

    def mentor_at_school_period(teacher:, school:, school_period:, traits:)
      email = Faker::Internet.email(name: ::Teachers::Name.new(teacher).full_name)

      FactoryBot.create(
        :mentor_at_school_period,
        *traits.compact,
        teacher:,
        school:,
        email:,
        created_at: teacher.created_at,
        **school_period
      ).tap { |masp| log_mentor_at_school_period(mentor_at_school_period: masp) }
    end

    def set_ect_attributes(teacher:)
      teacher.update!(
        api_ect_training_record_id: SecureRandom.uuid
      )

      return unless rand_boolean(ECT_ELIGIBLE_FOR_TRAINING_RATIO)

      teacher.update!(
        ect_first_became_eligible_for_training_at: teacher.created_at + 3.months,
        ect_pupil_premium_uplift: rand_boolean(PUPIL_PREMIUM_UPLIFT_RATIO),
        ect_sparsity_uplift: rand_boolean(SPARSITY_UPLIFT_RATIO)
      )
    end

    def set_mentor_attributes(teacher:)
      teacher.update!(
        api_mentor_training_record_id: SecureRandom.uuid
      )

      return unless rand_boolean(MENTOR_ELIGIBLE_FOR_TRAINING_RATIO)

      teacher.update!(mentor_first_became_eligible_for_training_at: teacher.created_at + 2.months)
    end

    def create_teacher_id_change_for(teacher:)
      return unless rand_boolean(TEACHER_ID_CHANGE_RATIO)

      api_from_teacher_id = FactoryBot.create(:teacher, trs_first_name: teacher.trs_first_name, trn: Helpers::TRNGenerator.next).api_id

      FactoryBot.create(
        :teacher_id_change,
        teacher:,
        api_from_teacher_id:
      )
    end

    def assign_ect_to_mentor(teacher:, school:, mentor_at_school_period_record:)
      return unless rand_boolean(ASSIGN_ECT_TO_MENTOR_RATIO)

      # Assign an ECT to the mentor for the same period excluding ECTs who are already mentees
      ect_at_school_period = school.ect_at_school_periods.where.not(teacher_id: teacher.id).where.not(id: MentorshipPeriod.distinct.pluck(:ect_at_school_period_id)).started_on_or_after(mentor_at_school_period_record.started_on).finished_before(mentor_at_school_period_record.finished_on).last

      return if ect_at_school_period.blank?

      FactoryBot.create(:mentorship_period,
                        mentor: mentor_at_school_period_record,
                        mentee: ect_at_school_period,
                        started_on: ect_at_school_period.started_on,
                        finished_on: ect_at_school_period.finished_on)
    end

    def random_period(contract_period:)
      # Most of the training starts in September 1 - 30
      started_on = Date.new(contract_period.year, 9, rand(1..30))

      # Some (5%) can start Oct - Jan
      started_on += 100.days if rand_boolean(LATE_START_RATIO)

      # Set 70% to finish 200-300 days after starting
      if rand_boolean(FINISHED_PERIOD_RATIO)
        finished_on = started_on + rand(200..300).days
      end

      { started_on:, finished_on: }
    end

    def random_period_within(started_on:, finished_on:)
      started_on = rand(started_on..(started_on + rand(100).days))
      finished_on = rand(started_on.tomorrow..finished_on) if finished_on

      { started_on:, finished_on: }
    end

    def random_appropriate_body
      AppropriateBodyPeriod.order(Arel.sql("RANDOM()")).first
    end

    def log_ect_at_school_period(ect_at_school_period:)
      suffix = "(ECT at school period)"
      log_seed_info(
        "* has been an ECT at #{ect_at_school_period.school.name} " \
        "#{describe_period_duration(ect_at_school_period)} #{suffix}",
        indent: 4
      )
    end

    def log_mentor_at_school_period(mentor_at_school_period:)
      suffix = "(mentor at school period)"
      log_seed_info(
        "* was a mentor at #{mentor_at_school_period.school.name} " \
        "from #{mentor_at_school_period.started_on} " \
        "#{describe_period_duration(mentor_at_school_period)} #{suffix}",
        indent: 4
      )
    end

    def log_training_period(training_period:)
      prefix = training_period.started_on.future? ? "will be" : "was"

      return unless training_period.provider_led_training_programme? && training_period.school_partnership.present?

      training_status = ::API::TrainingPeriods::TrainingStatus.new(training_period:).status
      suffix = "(training period - provider-led - #{training_status})"

      delivery_partnership = training_period.school_partnership.lead_provider_delivery_partnership

      lead_provider_name = delivery_partnership.active_lead_provider.lead_provider.name
      delivery_partner_name = delivery_partnership.delivery_partner.name

      log_seed_info(
        "* #{prefix} trained by #{lead_provider_name} (LP) " \
        "and #{delivery_partner_name} (DP) " \
        "#{describe_period_duration(training_period)} #{suffix}",
        indent: 4,
        colour: TRAINING_STATUS_COLOURS[training_status]
      )
    end

    def describe_period_duration(period)
      case
      when period.started_on.future?
        "from #{period.started_on}"
      when period.finished_on
        "between #{period.started_on} and #{period.finished_on}"
      else
        "since #{period.started_on}"
      end
    end

    def create_induction_period(teacher:)
      return unless rand_boolean(ECT_INDUCTION_RATIO)

      # Use the earliest ECT at school period for induction
      school_period = teacher.earliest_ect_at_school_period
      return unless school_period

      # Induction starts around the same time as school period
      started_on = (school_period.started_on + rand(-3..3).days)

      # Induction start can't be in the future
      return if started_on.future?

      # Induction finishes around 2 years after start (+- 30 days)
      finished_on = (school_period.started_on + 2.years + rand(-30..30).days)
      finished_on = nil if finished_on.future?

      if finished_on
        outcome = %i[pass fail].sample
        number_of_terms = 1
      end
      FactoryBot.create(:induction_period, outcome:, teacher:, started_on:, finished_on:, number_of_terms:)
    end

    def rand_boolean(ratio)
      Faker::Boolean.boolean(true_ratio: ratio)
    end
  end
end
