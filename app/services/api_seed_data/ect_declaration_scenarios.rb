module APISeedData
  class ECTDeclarationScenarios < Base
    NUMBER_OF_RECORDS_PER_SCENARIO = 3

    def plant
      return unless plantable?

      log_plant_info("api testing 2025 ECT declaration seed scenarios")

      NUMBER_OF_RECORDS_PER_SCENARIO.times do
        # ECT with a retained-1 declaration but no started declaration
        seed_retained_1_declaration_without_started_declaration

        # ECT with a paid started declaration and a submitted retained 2 declaration
        seed_paid_started_declaration_and_submitted_retained_2_declaration
      end
    end

  private

    def seed_retained_1_declaration_without_started_declaration
      active_lead_providers.find_each do |active_lead_provider|
        school_partnership = school_partnerships(active_lead_provider:).sample
        school = school_partnership.school
        school_time_period = { started_on: Date.new(contract_period.year, 9, 2), finished_on: nil }
        teacher = create_teacher(school_time_period:)
        ect_at_school_period = create_at_school_period(school_time_period:, teacher:, school:)
        training_time_period = { started_on: school_time_period[:started_on], finished_on: nil }
        training_period = create_training_period(ect_at_school_period:, school_partnership:, training_time_period:)
        create_ongoing_induction_period(teacher:, school_time_period:)
        create_declaration(state: :paid, declaration_type: :"retained-1", training_period:, declaration_date: Date.new(2026, 1, 1))

        log_plant_info("Created participant for #{school_partnership.active_lead_provider.lead_provider.name} with retained-1 declaration and no started declaration")
      end
    end

    def seed_paid_started_declaration_and_submitted_retained_2_declaration
      active_lead_providers.find_each do |active_lead_provider|
        school_partnership = school_partnerships(active_lead_provider:).sample
        school = school_partnership.school
        school_time_period = { started_on: Date.new(contract_period.year, 9, 1), finished_on: nil }
        teacher = create_teacher(school_time_period:)
        ect_at_school_period = create_at_school_period(school_time_period:, teacher:, school:)
        training_time_period = { started_on: school_time_period[:started_on], finished_on: nil }
        training_period = create_training_period(ect_at_school_period:, school_partnership:, training_time_period:)
        create_ongoing_induction_period(teacher:, school_time_period:)
        create_declaration(state: :paid, declaration_type: :started, training_period:, declaration_date: Date.new(2025, 9, 1))
        create_declaration(state: :no_payment, declaration_type: :"retained-2", training_period:, declaration_date: Date.new(2025, 9, 2))

        log_plant_info("Created participant for #{school_partnership.active_lead_provider.lead_provider.name} with paid started declaration and submitted retained-2 declaration")
      end
    end

    def contract_period
      @contract_period ||= ContractPeriod.find_by(year: 2025)
    end

    def active_lead_providers
      @active_lead_providers ||= super.where(contract_period:)
    end

    def schedule
      Schedule.find_by(contract_period:, identifier: "ecf-standard-september")
    end

    def school_partnerships(active_lead_provider:)
      SchoolPartnership
        .joins(:school, :lead_provider_delivery_partnership, :contract_period)
        .where(lead_provider_delivery_partnership: { active_lead_provider: })
    end

    def create_declaration(state:, declaration_type:, training_period:, declaration_date:)
      FactoryBot.create(:declaration, state, declaration_type:, training_period:, declaration_date:)
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
