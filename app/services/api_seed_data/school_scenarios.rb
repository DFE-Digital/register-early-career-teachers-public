require Rails.root.join("db/seeds/support/school_transfer_helpers")

module APISeedData
  class SchoolScenarios < Base
    include SchoolTransferHelpers

    def plant
      return unless plantable?

      log_plant_info("api school seed scenarios")

      # 5x schools that have minimum 1 participant registered with the lead provider as training them,
      # but without any partnership created yet
      schools_with_participants_with_lead_provider_as_expression_of_interest(count: 5)

      # 5x schools that for 2025 have minimum 1 participant registered with the lead provider as training them,
      # and a rolled over partnership from 2024
      schools_with_participants_that_rolled_over_from_2024_to_2025_with_lead_provider(count: 5)

      # 2x schools where they registered at least 1 participant with a lead provider, a partnership was
      # confirmed/created which still exists, but then the school changed the lead provider for that all
      # participants to a different lead provider
      schools_with_participants_with_lead_provider_where_all_transferred_to_another_lead_provider(count: 2)

      # 5x schools without any participants yet, that are already in partnership with the lead provider
      schools_without_participants_and_with_partnership(count: 5)

      # 5x schools without any participants yet, that are not in partnership with any lead providers
      schools_without_participants_and_without_partnership(count: 5)

      # 5x schools with partnerships and participants with a lead provider in 2024 (where expression_of_interest
      # should show as TRUE as a result of this)
      schools_with_participants_with_lead_provider_with_eoi_and_partnership_in_2024(count: 5)

      # 5x schools with only school-led ECTs and mentors (this doesn't have to be lead provider specific)
      schools_with_school_led_participants_only(count: 5)

      # 20x schools that have at least 1 provider-led ECT or mentor (this doesn't have to be lead provider specific)
      schools_with_provider_led_participants(count: 20)

      # 5x schools where in 2025 training took place with a lead provider and then all participants changed to
      # participant_status left, where EOI should still show as TRUE and a partnership still exists,
      # they'd still see participants, but participants_currently_training would be 0
      schools_with_participants_trained_2025_and_finished_with_lead_provider_where_all_transferred_to_another_lead_provider(count: 5)

      # 5x schools with ECTs and mentors currently in training with the lead provider
      schools_with_ects_and_mentors_training_with_lead_provider(count: 5)

      # 5x schools with multiple partnerships with the lead provider, e.g. with different delivery partner IDs
      schools_with_multiple_partnerships_with_lead_provider(count: 5)

      # 5x schools with multiple partnerships with that lead provider and another lead provider
      schools_with_multiple_partnerships_with_lead_provider_and_with_another_lead_provider(count: 5)
    end

    def plant_only(scenario, count:)
      send(scenario, count:)
    end

  private

    def schools_with_participants_with_lead_provider_as_expression_of_interest(count:)
      LeadProvider.find_each do |lead_provider|
        # Find a contract period that is not frozen and has an active lead provider (randomly chosen)
        active_lead_provider = ActiveLeadProvider
          .joins(:contract_period)
          .where(lead_provider:)
          .where(contract_periods: { payments_frozen_at: nil })
          .order("RANDOM()")
          .first

        next unless active_lead_provider

        # Count schools with participants linked via expression_of_interest (not school_partnership)
        # Check against ALL active_lead_providers for this lead_provider
        active_lead_provider_ids = lead_provider.active_lead_providers.pluck(:id)

        schools_with_ects = School
          .joins(ect_at_school_periods: :training_periods)
          .where(training_periods: { expression_of_interest_id: active_lead_provider_ids, school_partnership_id: nil })
          .pluck(:id)

        schools_with_mentors = School
          .joins(mentor_at_school_periods: :training_periods)
          .where(training_periods: { expression_of_interest_id: active_lead_provider_ids, school_partnership_id: nil })
          .pluck(:id)

        existing_count = School.where(id: schools_with_ects + schools_with_mentors).count

        missing_count = [count - existing_count, 0].max
        missing_count.times do
          school = create_school
          start_date = 6.months.ago.to_date
          type = %i[ect mentor].sample

          school_period = FactoryBot.create(:"#{type}_at_school_period", school:, started_on: start_date)

          FactoryBot.create(
            :training_period,
            :"for_#{type}",
            :provider_led,
            :with_schedule,
            started_on: start_date,
            "#{type}_at_school_period" => school_period,
            school_partnership: nil,
            expression_of_interest: active_lead_provider
          )

          log_seed_info("Created school with #{type} via expression of interest with #{lead_provider.name}", colour: Colourize::COLOURS.keys.sample)
        end
      end
    end

    def schools_with_participants_that_rolled_over_from_2024_to_2025_with_lead_provider(count:)
      contract_period_2024 = find_or_create_contract_period(2024)
      contract_period_2025 = find_or_create_contract_period(2025)

      LeadProvider.find_each do |lead_provider|
        # Get or create active lead providers for both contract periods
        active_lead_provider_2024 = find_or_create_active_lead_provider(lead_provider:, contract_period: contract_period_2024)
        active_lead_provider_2025 = find_or_create_active_lead_provider(lead_provider:, contract_period: contract_period_2025)

        # Find Teachers (participants) that have training in BOTH 2024 AND 2025 with this lead provider
        teachers_with_2024 = teachers_with_training_in_year(year: 2024, lead_provider:)
        teachers_with_2025 = teachers_with_training_in_year(year: 2025, lead_provider:)

        # Schools with teachers who rolled over (same participant trained in both years with same LP)
        existing_count = School
          .joins(ect_at_school_periods: :teacher)
          .where(teachers: { id: teachers_with_2024 })
          .where(teachers: { id: teachers_with_2025 })
          .distinct
          .count

        missing_count = [count - existing_count, 0].max
        missing_count.times do
          school = create_school

          # Create school period starting in 2024, still ongoing
          school_period = FactoryBot.create(
            :ect_at_school_period,
            :ongoing,
            school:,
            started_on: Date.new(2024, 9, 1)
          )

          # Create school partnerships for 2024 and 2025
          delivery_partner = find_or_create_delivery_partner(active_lead_provider: active_lead_provider_2024)

          lpdp_2024 = find_or_create_lead_provider_delivery_partnership(active_lead_provider: active_lead_provider_2024, delivery_partner:)
          school_partnership_2024 = FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership: lpdp_2024)
          schedule_2024 = FactoryBot.create(:schedule, contract_period: contract_period_2024)

          lpdp_2025 = find_or_create_lead_provider_delivery_partnership(active_lead_provider: active_lead_provider_2025, delivery_partner:)
          school_partnership_2025 = FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership: lpdp_2025)
          schedule_2025 = FactoryBot.create(:schedule, contract_period: contract_period_2025)

          # 2024 training period (finished)
          FactoryBot.create(
            :training_period,
            :for_ect,
            :provider_led,
            ect_at_school_period: school_period,
            school_partnership: school_partnership_2024,
            schedule: schedule_2024,
            started_on: Date.new(2024, 9, 1),
            finished_on: Date.new(2025, 8, 31)
          )

          # 2025 training period (rollover - ongoing)
          FactoryBot.create(
            :training_period,
            :for_ect,
            :provider_led,
            :ongoing,
            ect_at_school_period: school_period,
            school_partnership: school_partnership_2025,
            schedule: schedule_2025,
            started_on: Date.new(2025, 9, 1)
          )

          log_seed_info("Created school with ECT rolled over from 2024 to 2025 with #{lead_provider.name}", colour: Colourize::COLOURS.keys.sample)
        end
      end
    end

    def schools_with_participants_with_lead_provider_where_all_transferred_to_another_lead_provider(count:)
      lead_providers = LeadProvider.all.to_a

      LeadProvider.find_each do |lead_provider|
        other_lead_providers = lead_providers - [lead_provider]
        other_lead_provider_ids = other_lead_providers.map(&:id)

        # Find ECT periods that have training with this lead provider
        ect_periods_with_lp = ECTAtSchoolPeriod
          .joins(training_periods: { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } })
          .where(active_lead_providers: { lead_provider_id: lead_provider.id })

        # Find ECT periods that also have training with a different lead provider
        ect_periods_transferred = ECTAtSchoolPeriod
          .joins(training_periods: { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } })
          .where(active_lead_providers: { lead_provider_id: other_lead_provider_ids })

        # Schools where the SAME ECT has both
        existing_count = School
          .joins(:ect_at_school_periods)
          .where(ect_at_school_periods: { id: ect_periods_with_lp.select(:id) })
          .where(ect_at_school_periods: { id: ect_periods_transferred.select(:id) })
          .distinct
          .count

        missing_count = [count - existing_count, 0].max
        missing_count.times do
          school = create_school
          other_lead_provider = other_lead_providers.sample

          # Create school period
          school_period = FactoryBot.create(
            :ect_at_school_period,
            :ongoing,
            school:
          )

          # Training with original lead provider (finished)
          add_training_period(
            school_period,
            programme_type: :provider_led,
            from: school_period.started_on,
            to: school_period.started_on + 3.months,
            with: lead_provider
          )

          # Training with new lead provider (ongoing - the transfer)
          add_training_period(
            school_period,
            programme_type: :provider_led,
            from: school_period.started_on + 3.months,
            with: other_lead_provider
          )

          log_seed_info("Created school with ECT transferred from #{lead_provider.name} to #{other_lead_provider.name}", colour: Colourize::COLOURS.keys.sample)
        end
      end
    end

    def schools_without_participants_and_with_partnership(count:)
      ActiveLeadProvider.find_each do |active_lead_provider|
        existing_count = School
          .joins(school_partnerships: { lead_provider_delivery_partnership: :active_lead_provider })
          .where(active_lead_providers: { id: active_lead_provider.id })
          .left_joins(:ect_at_school_periods, :mentor_at_school_periods)
          .where(ect_at_school_periods: { id: nil }, mentor_at_school_periods: { id: nil })
          .distinct
          .count

        missing_count = [count - existing_count, 0].max
        missing_count.times do
          school = create_school
          create_school_partnership(active_lead_provider:, school:)
        end
      end
    end

    def schools_without_participants_and_without_partnership(count:)
      existing_count = School
        .left_joins(:ect_at_school_periods, :mentor_at_school_periods, :school_partnerships)
        .where(ect_at_school_periods: { id: nil }, mentor_at_school_periods: { id: nil }, school_partnerships: { id: nil })
        .distinct
        .count

      missing_count = [count - existing_count, 0].max
      missing_count.times do
        create_school
      end
    end

    def schools_with_participants_with_lead_provider_with_eoi_and_partnership_in_2024(count:)
      contract_period_2024 = find_or_create_contract_period(2024)

      LeadProvider.find_each do |lead_provider|
        active_lead_provider_2024 = find_or_create_active_lead_provider(lead_provider:, contract_period: contract_period_2024)

        # Count schools with ECTs that have school_partnership
        # Having partnership makes EOI to be true for API
        existing_count = School
          .joins(ect_at_school_periods: { training_periods: [:schedule, { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } }] })
          .where(schedules: { contract_period_year: 2024 })
          .where(active_lead_providers: { lead_provider_id: lead_provider.id })
          .distinct
          .count

        missing_count = [count - existing_count, 0].max
        missing_count.times do
          school = create_school

          # Create school period starting in 2024
          school_period = FactoryBot.create(
            :ect_at_school_period,
            :ongoing,
            school:,
            started_on: Date.new(2024, 9, 1)
          )

          # Create school partnership for 2024
          delivery_partner = find_or_create_delivery_partner(active_lead_provider: active_lead_provider_2024)
          lpdp_2024 = find_or_create_lead_provider_delivery_partnership(active_lead_provider: active_lead_provider_2024, delivery_partner:)
          school_partnership_2024 = FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership: lpdp_2024)
          schedule_2024 = FactoryBot.create(:schedule, contract_period: contract_period_2024)

          # Create training period with both school_partnership and expression_of_interest
          FactoryBot.create(
            :training_period,
            :for_ect,
            :provider_led,
            ect_at_school_period: school_period,
            school_partnership: school_partnership_2024,
            schedule: schedule_2024,
            expression_of_interest: active_lead_provider_2024,
            started_on: Date.new(2024, 9, 1),
            finished_on: nil
          )

          log_seed_info("Created school with ECT with EOI and partnership in 2024 for #{lead_provider.name}", colour: Colourize::COLOURS.keys.sample)
        end
      end
    end

    def schools_with_school_led_participants_only(count:)
      # Find schools that have school_led training but NOT provider_led training
      schools_with_school_led = schools_with_programme(programme: "school_led")
      schools_with_provider_led = schools_with_programme(programme: "provider_led")

      existing_count = schools_with_school_led
        .where.not(id: schools_with_provider_led.select(:id))
        .count

      missing_count = [count - existing_count, 0].max
      missing_count.times do
        school = create_school

        school_period = FactoryBot.create(
          :ect_at_school_period,
          school:
        )

        FactoryBot.create(
          :training_period,
          :for_ect,
          :school_led,
          ect_at_school_period: school_period
        )
      end
    end

    def schools_with_provider_led_participants(count:)
      existing_count = schools_with_programme(programme: "provider_led").count

      missing_count = [count - existing_count, 0].max
      missing_count.times do
        school = create_school
        type = %i[ect mentor].sample

        school_period = FactoryBot.create(
          :"#{type}_at_school_period",
          school:
        )

        FactoryBot.create(
          :training_period,
          :"for_#{type}",
          :provider_led,
          "#{type}_at_school_period" => school_period
        )
      end
    end

    def schools_with_participants_trained_2025_and_finished_with_lead_provider_where_all_transferred_to_another_lead_provider(count:)
      contract_period_2025 = find_or_create_contract_period(2025)
      lead_providers = LeadProvider.all.to_a

      LeadProvider.find_each do |lead_provider|
        active_lead_provider_2025 = find_or_create_active_lead_provider(lead_provider:, contract_period: contract_period_2025)
        other_lead_providers = lead_providers - [lead_provider]

        # Count schools with finished ECTs that have:
        # - training in 2025 with this lead provider (via school_partnership)
        # - expression_of_interest set
        # - finished training in the past (finished_on < today)
        # - the SAME ECT also transferred to another lead provider
        other_lead_provider_ids = other_lead_providers.map(&:id)

        # Find ECT periods that trained with original LP in 2025 with EOI and finished
        ect_periods_with_original_lp = ECTAtSchoolPeriod
          .joins(training_periods: [:schedule, { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } }])
          .where(schedules: { contract_period_year: 2025 })
          .where(active_lead_providers: { lead_provider_id: lead_provider.id })
          .where.not(training_periods: { expression_of_interest_id: nil })
          .where(training_periods: { finished_on: ...Date.current })

        # Find ECT periods that also have training with a different LP
        ect_periods_also_with_other_lp = ECTAtSchoolPeriod
          .joins(training_periods: { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } })
          .where(active_lead_providers: { lead_provider_id: other_lead_provider_ids })

        # Schools where the SAME ECT has both
        existing_count = School
          .joins(:ect_at_school_periods)
          .where(ect_at_school_periods: { id: ect_periods_with_original_lp.select(:id) })
          .where(ect_at_school_periods: { id: ect_periods_also_with_other_lp.select(:id) })
          .distinct
          .count

        missing_count = [count - existing_count, 0].max
        missing_count.times do
          school = create_school
          other_lead_provider = other_lead_providers.sample
          other_active_lead_provider_2025 = find_or_create_active_lead_provider(lead_provider: other_lead_provider, contract_period: contract_period_2025)

          # Use hard-coded dates in 2025 (in the past)
          start_date = Date.new(2025, 9, 1)
          first_training_end = Date.new(2025, 10, 31)
          second_training_end = Date.new(2025, 11, 30)

          # Create finished school period
          school_period = FactoryBot.create(
            :ect_at_school_period,
            school:,
            started_on: start_date,
            finished_on: second_training_end
          )

          # Create school partnership for original lead provider
          delivery_partner = find_or_create_delivery_partner(active_lead_provider: active_lead_provider_2025)
          lpdp_original = find_or_create_lead_provider_delivery_partnership(active_lead_provider: active_lead_provider_2025, delivery_partner:)
          school_partnership_original = FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership: lpdp_original)
          schedule_2025 = FactoryBot.create(:schedule, contract_period: contract_period_2025)

          # Training with original lead provider (finished) - has school_partnership and EOI
          FactoryBot.create(
            :training_period,
            :for_ect,
            :provider_led,
            ect_at_school_period: school_period,
            school_partnership: school_partnership_original,
            schedule: schedule_2025,
            expression_of_interest: active_lead_provider_2025,
            started_on: start_date,
            finished_on: first_training_end
          )

          # Create school partnership for other lead provider
          other_delivery_partner = find_or_create_delivery_partner(active_lead_provider: other_active_lead_provider_2025)
          lpdp_other = find_or_create_lead_provider_delivery_partnership(active_lead_provider: other_active_lead_provider_2025, delivery_partner: other_delivery_partner)
          school_partnership_other = FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership: lpdp_other)

          # Training with new lead provider (also finished - the transfer)
          FactoryBot.create(
            :training_period,
            :for_ect,
            :provider_led,
            ect_at_school_period: school_period,
            school_partnership: school_partnership_other,
            schedule: schedule_2025,
            started_on: first_training_end,
            finished_on: second_training_end
          )

          log_seed_info("Created school with ECT trained in 2025, EOI+partnership with #{lead_provider.name}, transferred to #{other_lead_provider.name}", colour: Colourize::COLOURS.keys.sample)
        end
      end
    end

    def schools_with_ects_and_mentors_training_with_lead_provider(count:)
      LeadProvider.find_each do |lead_provider|
        # Randomly choose an available ActiveLeadProvider
        active_lead_provider = ActiveLeadProvider
          .where(lead_provider:)
          .order("RANDOM()")
          .first

        next unless active_lead_provider

        # Check by lead_provider_id since add_training_period creates partnerships based on date
        # (which may use a different active_lead_provider than the one being iterated)
        schools_with_ects = schools_with_provider_led_ongoing_training(lead_provider:, type: :ect)
        schools_with_mentors = schools_with_provider_led_ongoing_training(lead_provider:, type: :mentor)

        existing_count = schools_with_ects.where(id: schools_with_mentors.select(:id)).count

        missing_count = [count - existing_count, 0].max
        missing_count.times do
          school = create_school
          start_date = 6.months.ago.to_date

          # Create an ECT training with this lead provider
          ect_teacher = FactoryBot.create(:teacher)
          ect_school_period = FactoryBot.create(:ect_at_school_period, teacher: ect_teacher, school:, started_on: start_date)
          add_training_period(ect_school_period, programme_type: :provider_led, from: start_date, with: lead_provider)

          # Create a mentor training with this lead provider
          mentor_teacher = FactoryBot.create(:teacher)
          mentor_school_period = FactoryBot.create(:mentor_at_school_period, teacher: mentor_teacher, school:, started_on: start_date)
          add_training_period(mentor_school_period, programme_type: :provider_led, from: start_date, with: lead_provider)

          log_seed_info("Created school with ECT and mentor training with #{lead_provider.name}", colour: Colourize::COLOURS.keys.sample)
        end
      end
    end

    def schools_with_multiple_partnerships_with_lead_provider(count:)
      LeadProvider.find_each do |lead_provider|
        # Randomly choose an available ActiveLeadProvider
        active_lead_provider = ActiveLeadProvider
          .where(lead_provider:)
          .order("RANDOM()")
          .first

        next unless active_lead_provider

        # Count schools that have multiple partnerships with this lead_provider (different delivery partners)
        # but no partnerships with any other lead provider
        schools_with_other_lp = School
          .joins(school_partnerships: { lead_provider_delivery_partnership: :active_lead_provider })
          .where.not(active_lead_providers: { lead_provider_id: lead_provider.id })
          .select(:id)

        existing_count = School
          .joins(school_partnerships: { lead_provider_delivery_partnership: :active_lead_provider })
          .where(active_lead_providers: { lead_provider_id: lead_provider.id })
          .where.not(id: schools_with_other_lp)
          .group(:id)
          .having("COUNT(DISTINCT lead_provider_delivery_partnerships.delivery_partner_id) > 1")
          .count
          .size

        missing_count = [count - existing_count, 0].max
        missing_count.times do
          school = create_school

          # Create 2-3 partnerships with different delivery partners
          partnership_count = rand(2..3)
          partnership_count.times do
            delivery_partner = find_or_create_delivery_partner(active_lead_provider:)
            lead_provider_delivery_partnership = find_or_create_lead_provider_delivery_partnership(active_lead_provider:, delivery_partner:)
            FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:)
          end

          log_seed_info("Created school with multiple partnerships with #{lead_provider.name}", colour: Colourize::COLOURS.keys.sample)
        end
      end
    end

    def schools_with_multiple_partnerships_with_lead_provider_and_with_another_lead_provider(count:)
      lead_providers = LeadProvider.all.to_a

      LeadProvider.find_each do |lead_provider|
        # Randomly choose an available ActiveLeadProvider
        active_lead_provider = ActiveLeadProvider
          .where(lead_provider:)
          .order("RANDOM()")
          .first

        next unless active_lead_provider

        other_lead_providers = lead_providers.reject { |lp| lp.id == lead_provider.id }

        # Count schools that have multiple partnerships with this lead_provider AND at least one with another LP
        schools_with_multiple_partnerships_for_lp = School
          .joins(school_partnerships: { lead_provider_delivery_partnership: :active_lead_provider })
          .where(active_lead_providers: { lead_provider_id: lead_provider.id })
          .group(:id)
          .having("COUNT(DISTINCT lead_provider_delivery_partnerships.delivery_partner_id) > 1")
          .select(:id)

        schools_also_with_other_lp = School
          .joins(school_partnerships: { lead_provider_delivery_partnership: :active_lead_provider })
          .where.not(active_lead_providers: { lead_provider_id: lead_provider.id })
          .select(:id)

        existing_count = School
          .where(id: schools_with_multiple_partnerships_for_lp)
          .where(id: schools_also_with_other_lp)
          .count

        missing_count = [count - existing_count, 0].max
        missing_count.times do
          school = create_school

          # Create 2-3 partnerships with different delivery partners for main LP
          partnership_count = rand(2..3)
          partnership_count.times do
            delivery_partner = find_or_create_delivery_partner(active_lead_provider:)
            lead_provider_delivery_partnership = find_or_create_lead_provider_delivery_partnership(active_lead_provider:, delivery_partner:)
            FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:)
          end

          # Create 1 partnership with another lead provider
          other_lead_provider = other_lead_providers.sample
          other_active_lead_provider = ActiveLeadProvider.where(lead_provider: other_lead_provider).order("RANDOM()").first
          next unless other_active_lead_provider

          other_delivery_partner = find_or_create_delivery_partner(active_lead_provider: other_active_lead_provider)
          other_lpdp = find_or_create_lead_provider_delivery_partnership(active_lead_provider: other_active_lead_provider, delivery_partner: other_delivery_partner)
          FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership: other_lpdp)

          log_seed_info("Created school with multiple partnerships with #{lead_provider.name} and another LP", colour: Colourize::COLOURS.keys.sample)
        end
      end
    end

    def create_school
      urn = Helpers::SchoolURNGenerator.next
      school_type = %i[independent state_funded eligible ineligible].sample
      school = FactoryBot.create(:school, :with_induction_tutor, school_type, urn:)

      log_seed_info("#{school.name} - type: #{school_type}", colour: Colourize::COLOURS.keys.sample)

      school
    end

    def create_school_partnership(active_lead_provider:, school:)
      delivery_partner = find_or_create_delivery_partner(active_lead_provider:)
      lead_provider_delivery_partnership = find_or_create_lead_provider_delivery_partnership(active_lead_provider:, delivery_partner:)
      school_partnership = FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:)

      log_seed_info("#{school_partnership.school.name} -> #{school_partnership.lead_provider.name}", colour: Colourize::COLOURS.keys.sample)

      school_partnership
    end

    def find_or_create_delivery_partner(active_lead_provider:)
      existing_delivery_partner_ids = active_lead_provider.lead_provider_delivery_partnerships.pluck(:delivery_partner_id)

      DeliveryPartner.where.not(id: existing_delivery_partner_ids).order("RANDOM()").first ||
        create_delivery_partner
    end

    def find_or_create_lead_provider_delivery_partnership(active_lead_provider:, delivery_partner:)
      LeadProviderDeliveryPartnership.find_by(active_lead_provider:, delivery_partner:) ||
        FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:)
    end

    def create_delivery_partner
      FactoryBot.build(:delivery_partner).tap do
        log_seed_info(it.name, indent: 2)

        random_date = rand(1..100).days.ago
        it.update!(
          created_at: random_date,
          updated_at: random_date,
          api_updated_at: random_date
        )
      end
    end

    def find_or_create_contract_period(year)
      ContractPeriod.find_by(year:) ||
        FactoryBot.create(:contract_period, year:)
    end

    def find_or_create_active_lead_provider(lead_provider:, contract_period:)
      ActiveLeadProvider.find_by(lead_provider:, contract_period:) ||
        FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:)
    end

    def teachers_with_training_in_year(year:, lead_provider:)
      Teacher
        .joins(ect_at_school_periods: { training_periods: [:schedule, { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } }] })
        .where(schedules: { contract_period_year: year })
        .where(active_lead_providers: { lead_provider_id: lead_provider.id })
        .select(:id)
    end

    def schools_with_programme(programme:)
      School
        .left_joins(:ect_at_school_periods, :mentor_at_school_periods)
        .joins("LEFT JOIN training_periods AS ect_tp ON ect_tp.ect_at_school_period_id = ect_at_school_periods.id")
        .joins("LEFT JOIN training_periods AS mentor_tp ON mentor_tp.mentor_at_school_period_id = mentor_at_school_periods.id")
        .where("ect_tp.training_programme = :programme OR mentor_tp.training_programme = :programme", programme:)
        .distinct
    end

    def schools_with_provider_led_ongoing_training(lead_provider:, type:)
      school_period_join = type == :ect ? :ect_at_school_periods : :mentor_at_school_periods

      School
        .joins(school_period_join => { training_periods: { school_partnership: { lead_provider_delivery_partnership: :active_lead_provider } } })
        .where(active_lead_providers: { lead_provider_id: lead_provider.id })
        .where(training_periods: { training_programme: "provider_led" })
        .where(training_periods: { started_on: ..Time.zone.now })
        .where(training_periods: { finished_on: [nil, Time.zone.now..] })
        .distinct
    end
  end
end
