module SandboxSeedData
  class APITeachersWithHistories < Base
    NUMBER_OF_RECORDS = 500

    TRAINING_STATUS_COLOURS = {
      active: :green,
      withdrawn: :red,
      deferred: :yellow,
    }.freeze

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

  private

    def create_teacher
      teacher = FactoryBot.create(
        :teacher,
        :with_realistic_name,
        trn: Helpers::TRNGenerator.next
      ).tap do |t|
        random_date = rand(1..100).days.ago
        t.update!(created_at: random_date, updated_at: random_date)
      end

      log_seed_info(::Teachers::Name.new(teacher).full_name, indent: 2)
      teacher
    end

    def groups_of_active_lead_providers
      ActiveLeadProvider.all.group_by(&:lead_provider_id)
    end

    def create_api_teachers_records_for(active_lead_provider)
      school_partnership = find_school_partnership(active_lead_provider)
      return if school_partnership.blank?

      school = school_partnership.school
      finished_on = Faker::Boolean.boolean(true_ratio: 0.3) ? nil : 6.months.from_now.to_date

      teacher = create_teacher
      school_period = random_period_within(started_on: teacher.created_at.to_date, finished_on:)
      training_period_data = random_period_within(**school_period)
      training_period_traits = generate_training_period_traits
      ect_mentor_traits = generate_ect_mentor_school_period_traits
      ect_specific_traits = generate_ect_specific_traits
      schedule = find_schedule(school_partnership.contract_period)

      if Faker::Boolean.boolean(true_ratio: 0.5)
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
      if Faker::Boolean.boolean(true_ratio: 0.8)
        return Schedule.find_by(
          contract_period:,
          identifier: "ecf-standard-september"
        )
      end

      Schedule
        .where(contract_period:)
        .order(Arel.sql("RANDOM()"))
        .first
    end

    def generate_training_period_traits
      [].tap do |traits|
        if Faker::Boolean.boolean(true_ratio: 0.2)
          traits << :withdrawn
        elsif Faker::Boolean.boolean(true_ratio: 0.15)
          traits << :deferred
        end
      end
    end

    def generate_ect_mentor_school_period_traits
      [].tap do |traits|
        traits << :with_teacher_payments_frozen_year if Faker::Boolean.boolean(true_ratio: 0.10)
      end
    end

    def generate_ect_specific_traits
      [].tap do |traits|
        traits << :with_teacher_payments_frozen_year if Faker::Boolean.boolean(true_ratio: 0.1)
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

      if Faker::Boolean.boolean(true_ratio: 0.1)
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

      if Faker::Boolean.boolean(true_ratio: 0.1)
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

      return unless Faker::Boolean.boolean(true_ratio: 0.65)

      teacher.update!(
        ect_first_became_eligible_for_training_at: teacher.created_at + 3.months,
        ect_pupil_premium_uplift: Faker::Boolean.boolean(true_ratio: 0.15),
        ect_sparsity_uplift: Faker::Boolean.boolean(true_ratio: 0.20)
      )
    end

    def set_mentor_attributes(teacher:)
      teacher.update!(
        api_mentor_training_record_id: SecureRandom.uuid
      )

      return unless Faker::Boolean.boolean(true_ratio: 0.65)

      teacher.update!(mentor_first_became_eligible_for_training_at: teacher.created_at + 2.months)
    end

    def create_teacher_id_change_for(teacher:)
      return unless Faker::Boolean.boolean(true_ratio: 0.15)

      api_from_teacher_id = FactoryBot.create(:teacher, trs_first_name: teacher.trs_first_name, trn: Helpers::TRNGenerator.next).api_id

      FactoryBot.create(
        :teacher_id_change,
        teacher:,
        api_from_teacher_id:
      )
    end

    def assign_ect_to_mentor(teacher:, school:, mentor_at_school_period_record:)
      return unless Faker::Boolean.boolean(true_ratio: 0.20)

      # Assign an ECT to the mentor for the same period excluding ECTs who are already mentees
      ect_at_school_period = school.ect_at_school_periods.where.not(teacher_id: teacher.id).where.not(id: MentorshipPeriod.distinct.pluck(:ect_at_school_period_id)).started_on_or_after(mentor_at_school_period_record.started_on).finished_before(mentor_at_school_period_record.finished_on).last

      return if ect_at_school_period.blank?

      FactoryBot.create(:mentorship_period,
                        mentor: mentor_at_school_period_record,
                        mentee: ect_at_school_period,
                        started_on: ect_at_school_period.started_on,
                        finished_on: ect_at_school_period.finished_on)
    end

    def random_period_within(started_on:, finished_on:)
      started_on = rand(started_on..(finished_on || Time.zone.today))
      finished_on = finished_on.present? ? rand(started_on..finished_on) : nil

      { started_on:, finished_on: }
    end

    def random_appropriate_body
      AppropriateBody.order(Arel.sql("RANDOM()")).first
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
  end
end
