module Seeds
  class ReuseChoices
    BASE_URN = 9_100_100
    SCHEDULE_IDENTIFIER = "ecf-standard-september"

    LEAD_PROVIDER_REUSABLE_NAME =
      "Reuse – Lead Provider One"

    LEAD_PROVIDER_NOT_AVAILABLE_IN_TARGET_YEAR_NAME =
      "Reuse – Lead Provider X (not available in target year)"

    DELIVERY_PARTNER_REUSABLE_NAME =
      "Reuse – Delivery Partner One"

    DELIVERY_PARTNER_NOT_REUSABLE_NAME =
      "Reuse – Delivery Partner Two"

    APPROPRIATE_BODY_NAME =
      "Reuse – Appropriate Body"

    def initialize(contract_period_year:)
      @contract_period_year = contract_period_year
    end

    def call
      ensure_contract_periods!
      ensure_schedules!
      ensure_reference_data!
      ensure_target_year_availability_for_reusable_lead_provider!

      seed_blank_control_school!
      seed_reusable_previous_scenarios!
      seed_not_reusable_previous_scenarios!
    end

  private

    attr_reader :contract_period_year

    def ensure_contract_periods!
      existing = ContractPeriod.where(year: years).index_by(&:year)

      years.each do |year|
        next if existing.key?(year)

        ContractPeriod.create!(
          year:,
          started_on: Date.new(year, 6, 1),
          finished_on: Date.new(year + 1, 5, 31),
          enabled: true
        )
      end
    end

    def ensure_schedules!
      contract_periods_by_year = ContractPeriod.where(year: years).index_by(&:year)

      years.each do |year|
        contract_period = contract_periods_by_year.fetch(year)

        Schedule.find_or_create_by!(
          contract_period:,
          identifier: SCHEDULE_IDENTIFIER
        )
      end
    end

    def ensure_reference_data!
      LeadProvider.find_or_create_by!(name: LEAD_PROVIDER_REUSABLE_NAME)
      LeadProvider.find_or_create_by!(name: LEAD_PROVIDER_NOT_AVAILABLE_IN_TARGET_YEAR_NAME)

      DeliveryPartner.find_or_create_by!(name: DELIVERY_PARTNER_REUSABLE_NAME)
      DeliveryPartner.find_or_create_by!(name: DELIVERY_PARTNER_NOT_REUSABLE_NAME)

      AppropriateBody.find_or_create_by!(name: APPROPRIATE_BODY_NAME)
    end

    def ensure_target_year_availability_for_reusable_lead_provider!
      ActiveLeadProvider.find_or_create_by!(
        lead_provider: reusable_lead_provider,
        contract_period: target_contract_period
      )
    end

    def years
      (2021..contract_period_year).to_a
    end

    def target_contract_period
      @target_contract_period ||= ContractPeriod.find_by!(year: contract_period_year)
    end

    def reusable_lead_provider
      @reusable_lead_provider ||= LeadProvider.find_by!(name: LEAD_PROVIDER_REUSABLE_NAME)
    end

    def lead_provider_not_available_in_target_year
      @lead_provider_not_available_in_target_year ||=
        LeadProvider.find_by!(name: LEAD_PROVIDER_NOT_AVAILABLE_IN_TARGET_YEAR_NAME)
    end

    def reusable_delivery_partner
      @reusable_delivery_partner ||= DeliveryPartner.find_by!(name: DELIVERY_PARTNER_REUSABLE_NAME)
    end

    def not_reusable_delivery_partner
      @not_reusable_delivery_partner ||= DeliveryPartner.find_by!(name: DELIVERY_PARTNER_NOT_REUSABLE_NAME)
    end

    def matrix_appropriate_body
      @matrix_appropriate_body ||= AppropriateBody.find_by!(name: APPROPRIATE_BODY_NAME)
    end

    # Scenario group 1 – blank slate school
    def seed_blank_control_school!
      school = ensure_scenario_school!(
        offset: 0,
        gias_name: "Reuse scenario – blank slate (no previous programme)",
        set_provider_led_last_chosen: false,
        last_chosen_lead_provider: nil
      )

      ensure_school_partnership!(
        school:,
        lead_provider: reusable_lead_provider,
        delivery_partner: reusable_delivery_partner,
        year: contract_period_year
      )
    end

    # Scenario group 2 – previous programme reusable in target year
    def seed_reusable_previous_scenarios!
      scenarios = [
        { offset: 1, previous_year: 2024, type: :partnership },
        { offset: 2, previous_year: 2024, type: :eoi },
        { offset: 3, previous_year: 2023, type: :partnership },
        { offset: 4, previous_year: 2023, type: :eoi },
        { offset: 5, previous_year: 2022, type: :partnership },
        { offset: 6, previous_year: 2022, type: :eoi },
        { offset: 7, previous_year: 2021, type: :partnership },
        { offset: 8, previous_year: 2021, type: :eoi },
      ]

      scenarios.each { |scenario| seed_reusable_previous_scenario!(**scenario) }
    end

    def seed_reusable_previous_scenario!(offset:, previous_year:, type:)
      label = "Reuse scenario – #{previous_year} #{type_label(type)} (reusable)"
      school = ensure_scenario_school!(
        offset:,
        gias_name: label,
        set_provider_led_last_chosen: true,
        last_chosen_lead_provider: reusable_lead_provider
      )

      seed_previous_teacher_and_training!(
        school:,
        previous_year:,
        mode: type,
        lead_provider: reusable_lead_provider,
        delivery_partner_for_partnership: reusable_delivery_partner
      )

      case type
      when :partnership
        ensure_school_partnership!(
          school:,
          lead_provider: reusable_lead_provider,
          delivery_partner: reusable_delivery_partner,
          year: contract_period_year
        )
      when :eoi
        ActiveLeadProvider.find_or_create_by!(
          lead_provider: reusable_lead_provider,
          contract_period: target_contract_period
        )
      else
        raise ArgumentError, "Unknown type: #{type.inspect}"
      end
    end

    # Scenario group 3 – previous programme NOT reusable in target year
    #
    # Rules:
    # - partnership NOT reusable: LP exists in target year BUT pairing does NOT
    # - EOI NOT reusable: LP does NOT exist in target year (no ALP in target year)
    def seed_not_reusable_previous_scenarios!
      scenarios = [
        { offset: 9,  previous_year: 2024, type: :partnership },
        { offset: 10, previous_year: 2024, type: :eoi },
        { offset: 11, previous_year: 2023, type: :partnership },
        { offset: 12, previous_year: 2023, type: :eoi },
        { offset: 13, previous_year: 2022, type: :partnership },
        { offset: 14, previous_year: 2022, type: :eoi },
        { offset: 15, previous_year: 2021, type: :partnership },
        { offset: 16, previous_year: 2021, type: :eoi },
      ]

      scenarios.each { |scenario| seed_not_reusable_previous_scenario!(**scenario) }
    end

    def seed_not_reusable_previous_scenario!(offset:, previous_year:, type:)
      label = "Reuse scenario – #{previous_year} #{type_label(type)} (not reusable)"
      last_chosen_lead_provider =
        (type == :partnership) ? reusable_lead_provider : lead_provider_not_available_in_target_year

      school = ensure_scenario_school!(
        offset:,
        gias_name: label,
        set_provider_led_last_chosen: true,
        last_chosen_lead_provider:
      )

      seed_previous_teacher_and_training!(
        school:,
        previous_year:,
        mode: type,
        lead_provider: last_chosen_lead_provider,
        delivery_partner_for_partnership: not_reusable_delivery_partner
      )

      case type
      when :partnership
        ActiveLeadProvider.find_or_create_by!(
          lead_provider: reusable_lead_provider,
          contract_period: target_contract_period
        )
      when :eoi
        ActiveLeadProvider.where(
          lead_provider: lead_provider_not_available_in_target_year,
          contract_period: target_contract_period
        ).delete_all
      else
        raise ArgumentError, "Unknown type: #{type.inspect}"
      end
    end

    def type_label(type)
      case type
      when :partnership then "partnership"
      when :eoi then "expression of interest"
      else type.to_s
      end
    end

    # ONE ECT + ONE TrainingPeriod per school (+ InductionPeriod)
    def seed_previous_teacher_and_training!(school:, previous_year:, mode:, lead_provider:, delivery_partner_for_partnership:)
      previous_contract_period = ContractPeriod.find_by!(year: previous_year)
      previous_schedule = Schedule.find_by!(contract_period: previous_contract_period, identifier: SCHEDULE_IDENTIFIER)

      teacher = FactoryBot.create(:teacher)

      ect_period =
        FactoryBot.create(
          :ect_at_school_period,
          :finished,
          school:,
          teacher:,
          started_on: Date.new(previous_year, 9, 1),
          finished_on: Date.new(previous_year + 1, 7, 31),
          school_reported_appropriate_body: matrix_appropriate_body
        )

      InductionPeriod.find_or_create_by!(
        teacher: ect_period.teacher,
        started_on: ect_period.started_on
      ) do |ip|
        ip.finished_on = ect_period.finished_on
        ip.appropriate_body = matrix_appropriate_body
        ip.induction_programme = "fip"
        ip.training_programme = "provider_led"
        ip.number_of_terms = 3
      end

      active_lead_provider =
        ActiveLeadProvider.find_or_create_by!(
          lead_provider:,
          contract_period: previous_contract_period
        )

      school.update!(
        last_chosen_training_programme: "provider_led",
        last_chosen_lead_provider: active_lead_provider.lead_provider,
        last_chosen_appropriate_body: matrix_appropriate_body
      )

      case mode
      when :partnership
        school_partnership =
          ensure_school_partnership!(
            school:,
            lead_provider:,
            delivery_partner: delivery_partner_for_partnership,
            year: previous_year
          )

        TrainingPeriod.find_or_create_by!(
          ect_at_school_period: ect_period,
          mentor_at_school_period: nil,
          started_on: ect_period.started_on
        ) do |tp|
          tp.training_programme = "provider_led"
          tp.schedule = previous_schedule
          tp.school_partnership = school_partnership
          tp.expression_of_interest = nil
          tp.finished_on = ect_period.finished_on
        end

      when :eoi
        TrainingPeriod.find_or_create_by!(
          ect_at_school_period: ect_period,
          mentor_at_school_period: nil,
          started_on: ect_period.started_on
        ) do |tp|
          tp.training_programme = "provider_led"
          tp.schedule = previous_schedule
          tp.school_partnership = nil
          tp.expression_of_interest = active_lead_provider
          tp.finished_on = ect_period.finished_on
        end

      else
        raise ArgumentError, "Unknown mode: #{mode.inspect}"
      end
    end

    def ensure_scenario_school!(offset:, gias_name:, set_provider_led_last_chosen:, last_chosen_lead_provider:)
      urn = BASE_URN + offset

      ensure_gias_school!(urn:, name: gias_name)

      school = School.find_or_initialize_by(urn:)

      school.induction_tutor_name ||= "Reuse Tutor"
      school.induction_tutor_email ||= "reuse@example.com"

      if set_provider_led_last_chosen
        school.last_chosen_training_programme = "provider_led" if school.has_attribute?(:last_chosen_training_programme)
        school.last_chosen_lead_provider = last_chosen_lead_provider if school.respond_to?(:last_chosen_lead_provider=)
        school.last_chosen_appropriate_body = matrix_appropriate_body if school.has_attribute?(:last_chosen_appropriate_body_id)
      else
        school.last_chosen_training_programme = nil if school.has_attribute?(:last_chosen_training_programme)
        school.last_chosen_lead_provider_id = nil if school.has_attribute?(:last_chosen_lead_provider_id)
        school.last_chosen_appropriate_body = nil if school.has_attribute?(:last_chosen_appropriate_body_id)
      end

      school.save!
      school
    end

    def ensure_gias_school!(urn:, name:)
      desired = {
        name:,
        status: "open",
        type_name: "Community school",
        local_authority_code: 999,
        in_england: true,
        eligible: true,
        opened_on: Date.new(2000, 1, 1),
        section_41_approved: false
      }

      record = GIAS::School.find_or_initialize_by(urn:)
      permitted = desired.select { |k, _| record.has_attribute?(k) }
      record.assign_attributes(permitted)
      record.save!
      record
    end

    def ensure_school_partnership!(school:, lead_provider:, delivery_partner:, year:)
      contract_period = ContractPeriod.find_by!(year:)

      active_lead_provider =
        ActiveLeadProvider.find_or_create_by!(
          lead_provider:,
          contract_period:
        )

      lead_provider_delivery_partnership =
        LeadProviderDeliveryPartnership.find_or_create_by!(
          active_lead_provider:,
          delivery_partner:
        )

      SchoolPartnership.find_or_create_by!(
        school:,
        lead_provider_delivery_partnership:
      )
    end
  end
end
