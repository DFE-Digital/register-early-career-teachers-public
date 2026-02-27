module APISeedData
  class ECTParticipantActionScenarios < Base
    NUMBER_OF_RECORDS_PER_SCENARIO = 3

    def plant
      return unless plantable?

      log_plant_info("api testing 2024 ECT participant seed scenarios")

      NUMBER_OF_RECORDS_PER_SCENARIO.times do
        # Allowing lead providers to resume a participant without errors
        seed_resumable_participants

        # Preventing lead providers from resuming a participant as the participant has started with another lead provider
        seed_participants_started_with_another_lead_provider

        # Participant with billable declaration that can have their contract period and schedule identifier changed
        seed_participant_with_billable_declaration_that_can_have_contract_period_and_schedule_changed
      end
    end

  private

    def seed_resumable_participants
      active_lead_providers.find_each do |active_lead_provider|
        # Withdrawn training period at ongoing school period, with ongoing induction period
        school_partnership = school_partnerships(active_lead_provider:).sample
        school = school_partnership.school
        school_time_period = { started_on: Date.new(contract_period.year, 9, rand(1..30)), finished_on: nil }
        teacher = create_teacher(school_time_period:)
        ect_at_school_period = create_at_school_period(school_time_period:, teacher:, school:)
        training_time_period = { started_on: school_time_period[:started_on], finished_on: school_time_period[:started_on] + rand(50..100).days }
        create_training_period(ect_at_school_period:, school_partnership:, training_time_period:, traits: [:withdrawn])
        create_ongoing_induction_period(teacher:, school_time_period:)

        log_plant_info("Created resumable participant for #{school_partnership.active_lead_provider.lead_provider.name}")
      end
    end

    def seed_participants_started_with_another_lead_provider
      active_lead_providers.find_each do |active_lead_provider|
        # Withdrawn training period at ongoing school period, with ongoing induction period
        # Where the school has a partnership with another active lead provider in the same year
        year = active_lead_provider.contract_period_year
        schools = school_partnerships(excluding_active_lead_provider: active_lead_provider, year:).map(&:school)
        school_partnership = school_partnerships(active_lead_provider:, school: schools).sample
        school_partnership = FactoryBot.create(:school_partnership, :for_year, year:, lead_provider: active_lead_provider.lead_provider, school: schools.sample) if school_partnership.nil?
        school = school_partnership.school
        school_time_period = { started_on: Date.new(contract_period.year, 9, rand(1..30)), finished_on: nil }
        teacher = create_teacher(school_time_period:)
        ect_at_school_period = create_at_school_period(school_time_period:, teacher:, school:)
        training_time_period = { started_on: school_time_period[:started_on], finished_on: school_time_period[:started_on] + rand(50..100).days }
        training_period_at_first_school = create_training_period(ect_at_school_period:, school_partnership:, training_time_period:, traits: [:withdrawn])
        create_ongoing_induction_period(teacher:, school_time_period:)

        # Active training period at the same school but with a different lead provider
        school_partnership = school_partnerships(excluding_active_lead_provider: active_lead_provider, year: contract_period.year, school:).sample
        training_time_period = { started_on: training_period_at_first_school.finished_on, finished_on: nil }
        create_training_period(ect_at_school_period:, school_partnership:, training_time_period:)

        log_plant_info("Created participant started with another lead provider for #{school_partnership.active_lead_provider.lead_provider.name}")
      end
    end

    def seed_participant_with_billable_declaration_that_can_have_contract_period_and_schedule_changed
      active_lead_providers.find_each do |active_lead_provider|
        # Ongoing training period/school period/induction period at a school where the lead provider
        # has a school partnership with the same school in a different contract period.
        other_years = ContractPeriod.where.not(year: contract_period.year).where(payments_frozen_at: nil).pluck(:year)
        schools = school_partnerships(year: other_years).excluding { it.lead_provider == active_lead_provider.lead_provider }.map(&:school)
        school_partnership = school_partnerships(active_lead_provider:, school: schools).sample
        school = school_partnership.school
        school_time_period = { started_on: Date.new(contract_period.year, 9, rand(1..30)), finished_on: nil }
        teacher = create_teacher(school_time_period:)
        ect_at_school_period = create_at_school_period(school_time_period:, teacher:, school:)
        training_time_period = { started_on: school_time_period[:started_on], finished_on: nil }
        training_period = create_training_period(ect_at_school_period:, school_partnership:, training_time_period:)
        create_ongoing_induction_period(teacher:, school_time_period:)

        # Started, paid declaration for the training period.
        create_declaration(state: :paid, declaration_type: :started, training_period:)

        log_plant_info("Created participant with declaration that can change contract period/schedule for #{school_partnership.active_lead_provider.lead_provider.name}")
      end
    end

    def contract_period
      @contract_period ||= ContractPeriod.find_by(year: 2024)
    end

    def active_lead_providers
      @active_lead_providers ||= ActiveLeadProvider.where(contract_period:)
    end

    def schedule
      Schedule.find_by(contract_period:, identifier: "ecf-standard-september")
    end

    def create_declaration(state:, declaration_type:, training_period:)
      milestone = schedule.milestones.find_by(declaration_type:)
      end_date = [milestone&.start_date, 1.day.ago].compact.max

      declaration_date = if milestone
                           Faker::Date.between(from: milestone.start_date, to: milestone.milestone_date || end_date)
                         else
                           Faker::Date.between(from: Date.new(schedule.contract_period.year), to: end_date)
                         end

      FactoryBot.create(:declaration, state, declaration_type:, training_period:, declaration_date:)
    end

    def school_partnerships(active_lead_provider: nil, excluding_active_lead_provider: nil, year: nil, school: nil)
      school_partnerships = SchoolPartnership
        .joins(:school, :lead_provider_delivery_partnership, :contract_period)

      school_partnerships = school_partnerships.where(lead_provider_delivery_partnership: { active_lead_provider: }) if active_lead_provider
      school_partnerships = school_partnerships.where.not(lead_provider_delivery_partnership: { active_lead_provider: excluding_active_lead_provider }) if excluding_active_lead_provider
      school_partnerships = school_partnerships.where(contract_periods: { year: }) if year
      school_partnerships = school_partnerships.where(school:) if school

      school_partnerships
    end

    def create_ongoing_induction_period(teacher:, school_time_period:)
      started_on = school_time_period[:started_on]
      FactoryBot.create(:induction_period, outcome: nil, teacher:, started_on:, finished_on: nil, number_of_terms: nil)
    end

    def create_teacher(school_time_period:)
      created_at = school_time_period[:started_on].to_time + rand(60 * 23).minutes
      FactoryBot.create(
        :teacher,
        :with_realistic_name,
        trn: APISeedData::Helpers::TRNGenerator.next,
        ect_first_became_eligible_for_training_at: created_at
      ).tap do |t|
        t.update!(
          created_at:,
          updated_at: created_at,
          api_updated_at: created_at
        )
      end
    end

    def create_at_school_period(school_time_period:, teacher:, school:)
      email = Faker::Internet.email(name: ::Teachers::Name.new(teacher).full_name)
      school_reported_appropriate_body = AppropriateBodyPeriod.order(Arel.sql("RANDOM()")).first
      FactoryBot.create(
        :ect_at_school_period,
        teacher:,
        school:,
        email:,
        school_reported_appropriate_body:,
        created_at: teacher.created_at,
        **school_time_period
      )
    end

    def create_training_period(ect_at_school_period:, school_partnership:, training_time_period:, traits: [])
      FactoryBot.create(
        :training_period,
        *traits,
        :with_schedule,
        :for_ect,
        schedule:,
        ect_at_school_period:,
        school_partnership:,
        **training_time_period
      )
    end
  end
end
