module APISeedData
  class TeachersWithChangeSchedule < Base
    NUMBER_OF_RECORDS = 1 # 1x ECT + 1x Mentor
    CHANGE_FROM_CONTRACT_PERIOD_YEAR = 2022

    CHANGE_VARIATIONS = [
      { change_contract_period: false, change_schedule: true },
      { change_contract_period: true, change_schedule: false },
      { change_contract_period: true, change_schedule: true },
    ].freeze

    TRAINEE_COLOURS = {
      ect: :magenta,
      mentor: :yellow,
    }.freeze

    def plant
      return unless plantable?

      log_plant_info("api teachers with change schedule")

      active_lead_providers.find_each do |active_lead_provider|
        %i[ect mentor].each do |trainee_type|
          CHANGE_VARIATIONS.each do |variation|
            NUMBER_OF_RECORDS.times do
              create_teacher_with_change_schedule(active_lead_provider:, trainee_type:, variation:)
            end
          end
        end
      end
    end

  protected

    def plantable?
      teachers_with_schedule_changes = Teacher.joins(ect_at_school_periods: :training_periods)
       .group("teachers.id")
       .having("COUNT(DISTINCT training_periods.schedule_id) > 1")

      super && teachers_with_schedule_changes.none?
    end

  private

    def contract_period
      @contract_period ||= ContractPeriod.find_by(year: CHANGE_FROM_CONTRACT_PERIOD_YEAR)
    end

    def active_lead_providers
      ActiveLeadProvider.where(contract_period:)
    end

    def create_teacher_with_change_schedule(active_lead_provider:, trainee_type:, variation:)
      teacher = create_teacher
      log_seed_info("#{::Teachers::Name.new(teacher).full_name} (#{trainee_type.upcase}) - #{variation.keep_if { |_k, v| v }.keys.join(', ')}", indent: 2, colour: TRAINEE_COLOURS[trainee_type])

      started_on = Date.new(contract_period.year, 9, 1) + rand(1..100).days
      at_school_period = FactoryBot.create(
        :"#{trainee_type}_at_school_period",
        teacher:,
        started_on:,
        finished_on: nil
      )

      school_partnership = random_school_partnership(active_lead_provider:)
      schedule = random_schedule(contract_period:, trainee_type:)
      finished_on = at_school_period.started_on + rand(1..100).days

      # Old training period
      create_training_period(
        trainee_type:,
        at_school_period:,
        started_on: at_school_period.started_on,
        finished_on:,
        schedule:,
        school_partnership:
      )

      # With new contract_period
      if variation[:change_contract_period]
        school_partnership = SchoolPartnership
          .includes(:lead_provider, :contract_period)
          .joins(:lead_provider)
          .where(
            school: school_partnership.school,
            lead_providers: { id: active_lead_provider.lead_provider.id }
          )
          .order("RANDOM()")
          .first!
        schedule = Schedule.find_by!(contract_period: school_partnership.contract_period, identifier: schedule.identifier)
      end

      # With new schedule
      if variation[:change_schedule]
        schedule = random_schedule(contract_period: school_partnership.contract_period, trainee_type:, excluding_schedule_identifier: schedule.identifier)
      end

      # New training period
      create_training_period(
        trainee_type:,
        at_school_period:,
        started_on: finished_on,
        finished_on: at_school_period.finished_on,
        schedule:,
        school_partnership:
      )
    end

    def create_teacher
      FactoryBot.create(
        :teacher,
        :with_realistic_name,
        trn: Helpers::TRNGenerator.next
      ).tap do |t|
        random_date = rand(1..100).days.ago
        t.update!(
          created_at: random_date,
          updated_at: random_date,
          api_updated_at: random_date
        )
      end
    end

    def create_training_period(trainee_type:, at_school_period:, started_on:, finished_on:, schedule:, school_partnership:)
      FactoryBot.create(
        :training_period,
        :"for_#{trainee_type}",
        :provider_led,
        "#{trainee_type}_at_school_period": at_school_period,
        started_on:,
        finished_on:,
        schedule:,
        school_partnership:
      ).tap { |training_period| log_training_period(training_period:) }
    end

    def random_school_partnership(active_lead_provider:, excluding_school: nil)
      SchoolPartnership
        .includes(lead_provider_delivery_partnership: :active_lead_provider)
        .where(lead_provider_delivery_partnership: { active_lead_provider: })
        .where.not(school: excluding_school)
        .order("RANDOM()")
        .first!
    end

    def random_schedule(contract_period:, trainee_type:, excluding_schedule_identifier: nil)
      if trainee_type == :mentor
        Schedule
          .where(contract_period:)
          .where.not(identifier: excluding_schedule_identifier)
          .order("RANDOM()")
          .first
      else
        Schedule
          .excluding_replacement_schedules
          .where(contract_period:)
          .where.not(identifier: excluding_schedule_identifier)
          .order("RANDOM()")
          .first
      end
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
        indent: 4
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
