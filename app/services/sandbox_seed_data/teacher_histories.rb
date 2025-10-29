module SandboxSeedData
  class TeacherHistories < Base
    TRAINING_STATUS_COLOURS = {
      active: :green,
      withdrawn: :red,
      deferred: :yellow,
    }.freeze

    def plant
      return unless plantable?

      log_plant_info("teacher histories")

      Teacher.find_each { create_history(it) }
    end

  private

    def create_history(teacher)
      log_seed_info(::Teachers::Name.new(teacher).full_name, indent: 2)

      traits = []

      traits << training_status_trait

      school_partnership = random_school_partnership
      school = school_partnership.school
      finished_on = Faker::Boolean.boolean(true_ratio: 0.3) ? nil : 6.months.from_now.to_date
      school_period = random_period_within(started_on: teacher.created_at.to_date, finished_on:)
      training_period = random_period_within(**school_period)

      if Faker::Boolean.boolean(true_ratio: 0.5)
        ect_at_school_period = ect_at_school_period(teacher:, school:, school_period:)
        FactoryBot.create(:training_period, *traits.compact, :for_ect, ect_at_school_period:, school_partnership:, **training_period).tap { log_training_period(training_period: it) }
        set_ect_eligible_for_funding(teacher:)
      else
        mentor_at_school_period = mentor_at_school_period(teacher:, school:, school_period:)
        FactoryBot.create(:training_period, *traits.compact, :for_mentor, mentor_at_school_period:, school_partnership:, **training_period).tap { log_training_period(training_period: it) }
        set_mentor_eligible_for_funding(teacher:)
      end
    end

    def training_status_trait
      if Faker::Boolean.boolean(true_ratio: 0.2)
        :withdrawn
      elsif Faker::Boolean.boolean(true_ratio: 0.15)
        :deferred
      end
    end

    def ect_at_school_period(teacher:, school:, school_period:)
      email = Faker::Internet.email(name: ::Teachers::Name.new(teacher).full_name)
      school_reported_appropriate_body = random_appropriate_body
      FactoryBot.create(
        :ect_at_school_period,
        teacher:,
        school:,
        email:,
        school_reported_appropriate_body:,
        **school_period
      ).tap { log_ect_at_school_period(ect_at_school_period: it) }
    end

    def mentor_at_school_period(teacher:, school:, school_period:)
      email = Faker::Internet.email(name: ::Teachers::Name.new(teacher).full_name)
      FactoryBot.create(
        :mentor_at_school_period,
        teacher:,
        school:,
        email:,
        **school_period
      ).tap { log_mentor_at_school_period(mentor_at_school_period: it) }
    end

    def set_ect_eligible_for_funding(teacher:)
      return unless Faker::Boolean.boolean(true_ratio: 0.65)

      teacher.update!(ect_first_became_eligible_for_training_at: 3.months.ago)
    end

    def set_mentor_eligible_for_funding(teacher:)
      return unless Faker::Boolean.boolean(true_ratio: 0.65)

      teacher.update!(mentor_first_became_eligible_for_training_at: 3.months.ago)
    end

    def random_period_within(started_on:, finished_on:)
      started_on = rand(started_on..(finished_on || Time.zone.today))

      finished_on = finished_on.present? ? rand(started_on..finished_on) : nil

      { started_on:, finished_on: }
    end

    def random_school_partnership
      SchoolPartnership.order("RANDOM()").first
    end

    def random_appropriate_body
      AppropriateBody.order("RANDOM()").first
    end

    def log_ect_at_school_period(ect_at_school_period:)
      suffix = "(ECT at school period)"

      log_seed_info("* has been an ECT at #{ect_at_school_period.school.name} #{describe_period_duration(ect_at_school_period)} #{suffix}", indent: 4)
    end

    def log_mentor_at_school_period(mentor_at_school_period:)
      suffix = "(mentor at school period)"

      log_seed_info("* was a mentor at #{mentor_at_school_period.school.name} from #{mentor_at_school_period.started_on} #{describe_period_duration(mentor_at_school_period)} #{suffix}", indent: 4)
    end

    def log_training_period(training_period:)
      prefix = (training_period.started_on.future?) ? "will be" : "was"

      if training_period.provider_led_training_programme? && training_period.school_partnership.present?
        training_status = ::API::TrainingPeriods::TrainingStatus.new(training_period:).status
        suffix = "(training period - provider-led - #{training_status})"
        delivery_partnership = training_period.school_partnership.lead_provider_delivery_partnership
        lead_provider_name = delivery_partnership.active_lead_provider.lead_provider.name
        delivery_partner_name = delivery_partnership.delivery_partner.name
        log_seed_info("* #{prefix} trained by #{lead_provider_name} (LP) and #{delivery_partner_name} (DP) #{describe_period_duration(training_period)} #{suffix}", indent: 4, colour: TRAINING_STATUS_COLOURS[training_status])
      end
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
