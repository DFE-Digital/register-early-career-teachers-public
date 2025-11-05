module APISeedData
  class ParticipantScenarios < Base
    NUMBER_OF_RECORDS_PER_SCENARIO = 5

    def plant
      return unless plantable?

      log_plant_info("api participant seed scenarios")

      # participants in each contract period
      participants_in_each_contract_period(count: NUMBER_OF_RECORDS_PER_SCENARIO)

      # in 2023 and 2024, some participants that are new to the lead provider (so the school would be EOI = true) without a partnership that exists yet
      participants_with_lead_provider_as_expression_of_interest(count: NUMBER_OF_RECORDS_PER_SCENARIO)

      # at least 5 ECTs with an induction_start_date
      ect_participants_with_induction_start_date(count: NUMBER_OF_RECORDS_PER_SCENARIO)

      # at least 5 ECTs without an induction_start_date
      ect_participants_without_induction_start_date(count: NUMBER_OF_RECORDS_PER_SCENARIO)

      # at least 2 ECTs and 2 mentors in each contract period from 2021-2025 with a range of billable declarations
      participants_with_declarations(count: NUMBER_OF_RECORDS_PER_SCENARIO)

      # at least 5 participants with training status "leaving"
      participants_with_training_status_leaving(count: NUMBER_OF_RECORDS_PER_SCENARIO)

      # at least 3 participants with participant status "joining"
      # and training status "active"
      active_participants_with_participant_status_joining(count: 3)
      # at least 3 participants with participant status "leaving"
      # and training status "active"
      active_participants_with_participant_status_leaving_in_the_future(count: 3)
      # at least 2 participants with participant status "left"
      # and training status "withdrawn"
      withdrawn_participants_with_participant_status_left(count: 2)
      # at least 2 participants with participant status "left"
      # and training status "active"
      active_participants_with_participant_status_left(count: 2)
    end

    def plant_only(scenario, count:, contract_period_years:)
      send(scenario, count:, contract_period_years:)
    end

  private

    def participants_in_each_contract_period(count:, contract_period_years: [2021, 2022, 2023, 2024, 2025])
      contract_period_years.each do |contract_period_year|
        contract_period = find_contract_period(contract_period_year)

        next unless contract_period

        ActiveLeadProvider.for_contract_period(contract_period.year).find_each do |active_lead_provider|
          # Count existing participants (ECTs and mentors) in this contract period with this lead provider
          existing_ects = Teacher
            .joins(ect_at_school_periods: { training_periods: :active_lead_provider })
            .where(active_lead_providers: { id: active_lead_provider })
            .distinct
            .count

          existing_mentors = Teacher
            .joins(mentor_at_school_periods: { training_periods: :active_lead_provider })
            .where(active_lead_providers: { id: active_lead_provider })
            .distinct
            .count

          existing_count = existing_ects + existing_mentors

          missing_count = [count - existing_count, 0].max
          missing_count.times do
            school_partnership = school_partnership(active_lead_provider)
            school = school_partnership.school
            type = %i[ect mentor].sample
            start_date = Date.new(contract_period.year, 9, 1)

            school_period = FactoryBot.create(
              :"#{type}_at_school_period",
              school:,
              started_on: start_date
            )

            schedule = find_schedule(contract_period)

            FactoryBot.create(
              :training_period,
              :"for_#{type}",
              :provider_led,
              :ongoing,
              "#{type}_at_school_period" => school_period,
              school_partnership:,
              schedule:,
              started_on: start_date
            )

            log_seed_info("Created #{type} in contract period #{contract_period.year} with #{active_lead_provider.lead_provider.name}", colour: Colourize::COLOURS.keys.sample)
          end
        end
      end
    end

    def participants_with_lead_provider_as_expression_of_interest(count:, contract_period_years: [2023, 2024])
      contract_period_years.each do |contract_period_year|
        contract_period = find_contract_period(contract_period_year)

        next unless contract_period

        ActiveLeadProvider.for_contract_period(contract_period.year).find_each do |active_lead_provider|
          # Count existing participants (ECTs and mentors) with EOI but no partnership in this contract period
          active_lead_provider_ids = active_lead_provider.lead_provider.active_lead_providers.where(contract_period:).pluck(:id)

          existing_ects = Teacher
            .joins(ect_at_school_periods: :training_periods)
            .where(training_periods: { expression_of_interest_id: active_lead_provider_ids, school_partnership_id: nil })
            .distinct
            .count

          existing_mentors = Teacher
            .joins(mentor_at_school_periods: :training_periods)
            .where(training_periods: { expression_of_interest_id: active_lead_provider_ids, school_partnership_id: nil })
            .distinct
            .count

          existing_count = existing_ects + existing_mentors

          missing_count = [count - existing_count, 0].max
          missing_count.times do
            school_partnership = school_partnership(active_lead_provider)
            school = school_partnership.school
            type = %i[ect mentor].sample
            start_date = Date.new(contract_period_year, 9, 1)

            school_period = FactoryBot.create(
              :"#{type}_at_school_period",
              school:,
              started_on: start_date
            )

            schedule = find_schedule(contract_period)

            FactoryBot.create(
              :training_period,
              :"for_#{type}",
              :provider_led,
              :ongoing,
              "#{type}_at_school_period" => school_period,
              school_partnership: nil,
              expression_of_interest: active_lead_provider,
              schedule:,
              started_on: start_date
            )

            log_seed_info("Created #{type} with EOI (no partnership) in contract period #{contract_period_year} with #{active_lead_provider.lead_provider.name}", colour: Colourize::COLOURS.keys.sample)
          end
        end
      end
    end

    def ect_participants_with_induction_start_date(count:, contract_period_years: [2021, 2022, 2023, 2024, 2025])
      contract_period_years.each do |contract_period_year|
        contract_period = find_contract_period(contract_period_year)

        next unless contract_period

        ActiveLeadProvider.for_contract_period(contract_period.year).find_each do |active_lead_provider|
          existing_count = Teacher
            .joins(:induction_periods, ect_at_school_periods: { training_periods: :active_lead_provider })
            .where.not(induction_periods: { started_on: nil })
            .where(active_lead_providers: { id: active_lead_provider })
            .distinct
            .count

          missing_count = [count - existing_count, 0].max
          missing_count.times do
            school_partnership = school_partnership(active_lead_provider)
            school = school_partnership.school
            start_date = Date.new(contract_period_year, 9, 1)

            school_period = FactoryBot.create(
              :ect_at_school_period,
              :ongoing,
              school:,
              started_on: start_date
            )

            schedule = find_schedule(contract_period)

            FactoryBot.create(
              :training_period,
              :for_ect,
              :provider_led,
              :ongoing,
              ect_at_school_period: school_period,
              school_partnership:,
              schedule:,
              started_on: start_date
            )

            FactoryBot.create(
              :induction_period,
              teacher: school_period.teacher,
              started_on: start_date,
              appropriate_body_period: random_or_create_appropriate_body
            )

            log_seed_info("Created ECT with induction start date #{start_date} in contract period #{contract_period_year} with #{active_lead_provider.lead_provider.name}", colour: Colourize::COLOURS.keys.sample)
          end
        end
      end
    end

    def ect_participants_without_induction_start_date(count:, contract_period_years: [2021, 2022, 2023, 2024, 2025])
      contract_period_years.each do |contract_period_year|
        contract_period = find_contract_period(contract_period_year)

        next unless contract_period

        ActiveLeadProvider.for_contract_period(contract_period.year).find_each do |active_lead_provider|
          existing_count = Teacher
            .joins(ect_at_school_periods: { training_periods: :active_lead_provider })
            .where.missing(:induction_periods)
            .where(active_lead_providers: { id: active_lead_provider })
            .distinct
            .count

          missing_count = [count - existing_count, 0].max
          missing_count.times do
            school_partnership = school_partnership(active_lead_provider)
            school = school_partnership.school
            start_date = Date.new(contract_period_year, 9, 1)

            school_period = FactoryBot.create(
              :ect_at_school_period,
              :ongoing,
              school:,
              started_on: start_date
            )

            schedule = find_schedule(contract_period)

            FactoryBot.create(
              :training_period,
              :for_ect,
              :provider_led,
              :ongoing,
              ect_at_school_period: school_period,
              school_partnership:,
              schedule:,
              started_on: start_date
            )

            log_seed_info("Created ECT without induction start date in contract period #{contract_period_year} with #{active_lead_provider.lead_provider.name}", colour: Colourize::COLOURS.keys.sample)
          end
        end
      end
    end

    def participants_with_declarations(count:, contract_period_years: [2021, 2022, 2023, 2024, 2025])
      billable_statuses = Declaration::BILLABLE_OR_CHANGEABLE_PAYMENT_STATUSES

      declaration_plan = {
        ect: [
          { declaration_type: "started", payment_status: :no_payment },
          { declaration_type: "retained-1", payment_status: :eligible },
          { declaration_type: "retained-2", payment_status: :payable },
          { declaration_type: "completed", payment_status: :payable },
          { declaration_type: "completed", payment_status: :paid }
        ],
        mentor: [
          { declaration_type: "started", payment_status: :no_payment },
          { declaration_type: "started", payment_status: :eligible },
          { declaration_type: "completed", payment_status: :payable },
          { declaration_type: "completed", payment_status: :paid }
        ]
      }

      contract_period_years.each do |contract_period_year|
        contract_period = find_contract_period(contract_period_year)

        next unless contract_period

        ActiveLeadProvider.for_contract_period(contract_period.year).find_each do |active_lead_provider|
          existing_ects = Teacher
            .joins(ect_at_school_periods: { training_periods: %i[declarations active_lead_provider] })
            .where(declarations: { payment_status: billable_statuses })
            .where(active_lead_providers: { id: active_lead_provider })
            .distinct
            .count

          existing_mentors = Teacher
            .joins(mentor_at_school_periods: { training_periods: %i[declarations active_lead_provider] })
            .where(declarations: { payment_status: billable_statuses })
            .where(active_lead_providers: { id: active_lead_provider })
            .distinct
            .count

          { ect: existing_ects, mentor: existing_mentors }.each do |type, existing_count|
            missing_count = [count - existing_count, 0].max
            next if missing_count.zero?

            missing_count.times do
              school_partnership = school_partnership(active_lead_provider)
              school = school_partnership.school
              start_date = Date.new(contract_period_year, 9, 1)
              school_period = FactoryBot.create(:"#{type}_at_school_period", :ongoing, school:, started_on: start_date)
              schedule = find_schedule(contract_period)
              teacher = school_period.teacher

              training_period = FactoryBot.create(
                :training_period,
                :"for_#{type}",
                :provider_led,
                :ongoing,
                "#{type}_at_school_period" => school_period,
                school_partnership:,
                schedule:,
                started_on: start_date,
                finished_on: nil
              )

              existing_declarations = if training_period.for_ect?
                                        teacher.ect_declarations
                                      else
                                        teacher.mentor_declarations
                                      end

              declaration_plan.fetch(type).each do |plan|
                payment_status = plan[:payment_status]
                declaration_type = plan[:declaration_type]

                payment_statement = if %i[eligible payable paid].include?(payment_status)
                                      find_random_statement(active_lead_provider)
                                    end

                declaration_date = declaration_date(schedule, declaration_type)

                declaration = FactoryBot.build(
                  :declaration,
                  training_period:,
                  declaration_type:,
                  payment_status:,
                  payment_statement:,
                  declaration_date:
                )

                next if existing_declarations.billable_or_changeable.where(declaration_type:).exists?
                next if %i[eligible payable paid].include?(payment_status) && !payment_statement

                declaration.save!
              end

              log_seed_info("Created #{type} with billable declarations in contract period #{contract_period_year} with #{active_lead_provider.lead_provider.name}", colour: Colourize::COLOURS.keys.sample)
            end
          end
        end
      end
    end

    def participants_with_training_status_leaving(count:, contract_period_years: [2021, 2022, 2023, 2024, 2025])
      contract_period_years.each do |contract_period_year|
        contract_period = find_contract_period(contract_period_year)

        next unless contract_period

        ActiveLeadProvider.for_contract_period(contract_period.year).find_each do |active_lead_provider|
          # Count existing participants with "leaving" training periods (to be finished in the future)
          existing_ects = Teacher
            .joins(ect_at_school_periods: { training_periods: :active_lead_provider })
            .where(training_periods: { finished_on: Time.zone.tomorrow.. })
            .where(active_lead_providers: { id: active_lead_provider })
            .distinct
            .count

          existing_mentors = Teacher
            .joins(mentor_at_school_periods: { training_periods: :active_lead_provider })
            .where(training_periods: { finished_on: Time.zone.tomorrow.. })
            .where(active_lead_providers: { id: active_lead_provider })
            .distinct
            .count

          { ect: existing_ects, mentor: existing_mentors }.each do |type, existing_count|
            missing_count = [count - existing_count, 0].max
            next if missing_count.zero?

            missing_count.times do
              school_partnership = school_partnership(active_lead_provider)
              next unless school_partnership

              school = school_partnership.school
              start_date = Date.new(contract_period_year, 9, 1)
              finished_date = Time.zone.today + rand(1..6).months

              school_period = FactoryBot.create(:"#{type}_at_school_period", :ongoing, school:, started_on: start_date, finished_on: finished_date)

              schedule = find_schedule(contract_period)

              FactoryBot.create(
                :training_period,
                :"for_#{type}",
                :provider_led,
                "#{type}_at_school_period" => school_period,
                school_partnership:,
                schedule:,
                started_on: start_date,
                finished_on: finished_date
              )

              log_participant_created(
                type:,
                participant_status: "leaving",
                training_status: "active",
                contract_period_year:,
                lead_provider_name: active_lead_provider.lead_provider.name
              )
            end
          end
        end
      end
    end

    def active_participants_with_participant_status_joining(count:, contract_period_years: [2025])
      contract_period_years.each do |contract_period_year|
        contract_period = find_contract_period(contract_period_year)

        next unless contract_period

        ActiveLeadProvider.for_contract_period(contract_period.year).find_each do |active_lead_provider|
          # Count existing participants with "joining" training periods (to be started in the future)
          existing_ects = Teacher
            .joins(ect_at_school_periods: { training_periods: :active_lead_provider })
            .where(training_periods: { started_on: Time.zone.tomorrow.. })
            .where(active_lead_providers: { id: active_lead_provider })
            .distinct
            .count

          existing_mentors = Teacher
            .joins(mentor_at_school_periods: { training_periods: :active_lead_provider })
            .where(training_periods: { started_on: Time.zone.tomorrow.. })
            .where(active_lead_providers: { id: active_lead_provider })
            .distinct
            .count

          { ect: existing_ects, mentor: existing_mentors }.each do |type, existing_count|
            missing_count = [count - existing_count, 0].max
            next if missing_count.zero?

            missing_count.times do
              school_partnership = school_partnership(active_lead_provider)
              next unless school_partnership

              school = school_partnership.school
              start_date = Time.zone.today + rand(1..6).months
              finished_date = start_date + rand(6..12).months

              school_period = FactoryBot.create(
                :"#{type}_at_school_period",
                school:,
                started_on: start_date,
                finished_on: finished_date
              )

              schedule = find_schedule(contract_period)

              FactoryBot.create(
                :training_period,
                :"for_#{type}",
                :provider_led,
                :active,
                "#{type}_at_school_period" => school_period,
                school_partnership:,
                schedule:,
                started_on: start_date,
                finished_on: finished_date
              )

              log_participant_created(
                type:,
                participant_status: "joining",
                training_status: "active",
                contract_period_year:,
                lead_provider_name: active_lead_provider.lead_provider.name
              )
            end
          end
        end
      end
    end

    def active_participants_with_participant_status_leaving_in_the_future(count:, contract_period_years: [2021, 2022, 2023, 2024, 2025])
      contract_period_years.each do |contract_period_year|
        contract_period = find_contract_period(contract_period_year)

        next unless contract_period

        ActiveLeadProvider.for_contract_period(contract_period.year).find_each do |active_lead_provider|
          # Count existing participants with "leaving" training periods (to be finished in the future)
          existing_ects = Teacher
            .joins(ect_at_school_periods: { training_periods: :active_lead_provider })
            .where(training_periods: { finished_on: 4.months.from_now.. })
            .where(active_lead_providers: { id: active_lead_provider })
            .distinct
            .count

          existing_mentors = Teacher
            .joins(mentor_at_school_periods: { training_periods: :active_lead_provider })
            .where(training_periods: { finished_on: 4.months.from_now.. })
            .where(active_lead_providers: { id: active_lead_provider })
            .distinct
            .count

          { ect: existing_ects, mentor: existing_mentors }.each do |type, existing_count|
            missing_count = [count - existing_count, 0].max
            next if missing_count.zero?

            missing_count.times do
              school_partnership = school_partnership(active_lead_provider)
              next unless school_partnership

              school = school_partnership.school
              start_date = Date.new(contract_period_year, 9, 1)
              finished_date = 4.months.from_now + rand(1..6).months

              school_period = FactoryBot.create(
                :"#{type}_at_school_period",
                school:,
                started_on: start_date,
                finished_on: finished_date
              )

              schedule = find_schedule(contract_period)

              FactoryBot.create(
                :training_period,
                :"for_#{type}",
                :provider_led,
                :active,
                "#{type}_at_school_period" => school_period,
                school_partnership:,
                schedule:,
                started_on: start_date,
                finished_on: finished_date
              )

              log_participant_created(
                type:,
                participant_status: "leaving",
                training_status: "active",
                contract_period_year:,
                lead_provider_name: active_lead_provider.lead_provider.name
              )
            end
          end
        end
      end
    end

    def withdrawn_participants_with_participant_status_left(count:, contract_period_years: [2021, 2022, 2023, 2024, 2025])
      contract_period_years.each do |contract_period_year|
        contract_period = find_contract_period(contract_period_year)

        next unless contract_period

        ActiveLeadProvider.for_contract_period(contract_period.year).find_each do |active_lead_provider|
          # Count existing participants with "leaving" training periods (to be finished in the future)
          existing_ects = Teacher
            .joins(ect_at_school_periods: { training_periods: :active_lead_provider })
            .where(training_periods: { started_on: ..Date.current, finished_on: ..Date.current })
            .where.not(training_periods: { withdrawn_at: nil })
            .where(active_lead_providers: { id: active_lead_provider })
            .distinct
            .count

          existing_mentors = Teacher
            .joins(mentor_at_school_periods: { training_periods: :active_lead_provider })
            .where(training_periods: { started_on: ..Date.current, finished_on: ..Date.current })
            .where.not(training_periods: { withdrawn_at: nil })
            .where(active_lead_providers: { id: active_lead_provider })
            .distinct
            .count

          { ect: existing_ects, mentor: existing_mentors }.each do |type, existing_count|
            missing_count = [count - existing_count, 0].max
            next if missing_count.zero?

            missing_count.times do
              school_partnership = school_partnership(active_lead_provider)
              next unless school_partnership

              school = school_partnership.school
              start_date = Date.new(contract_period_year, 9, 1)
              finished_date = Date.current - rand(1..8).weeks

              school_period = FactoryBot.create(
                :"#{type}_at_school_period",
                school:,
                started_on: start_date,
                finished_on: finished_date
              )

              schedule = find_schedule(contract_period)

              FactoryBot.create(
                :training_period,
                :"for_#{type}",
                :provider_led,
                :withdrawn,
                "#{type}_at_school_period" => school_period,
                school_partnership:,
                schedule:,
                started_on: start_date,
                finished_on: finished_date
              )

              log_participant_created(
                type:,
                participant_status: "left",
                training_status: "withdrawn",
                contract_period_year:,
                lead_provider_name: active_lead_provider.lead_provider.name
              )
            end
          end
        end
      end
    end

    def active_participants_with_participant_status_left(count:, contract_period_years: [2021, 2022, 2023, 2024, 2025])
      contract_period_years.each do |contract_period_year|
        contract_period = find_contract_period(contract_period_year)

        next unless contract_period

        ActiveLeadProvider.for_contract_period(contract_period.year).find_each do |active_lead_provider|
          # Count existing participants with "leaving" training periods (to be finished in the future)
          existing_ects = Teacher
            .joins(ect_at_school_periods: { training_periods: :active_lead_provider })
            .where(training_periods: { started_on: ..Date.current, finished_on: ..Date.current })
            .where(training_periods: { withdrawn_at: nil, deferred_at: nil })
            .where(active_lead_providers: { id: active_lead_provider })
            .distinct
            .count

          existing_mentors = Teacher
            .joins(mentor_at_school_periods: { training_periods: :active_lead_provider })
            .where(training_periods: { started_on: ..Date.current, finished_on: ..Date.current })
            .where(training_periods: { withdrawn_at: nil, deferred_at: nil })
            .where(active_lead_providers: { id: active_lead_provider })
            .distinct
            .count

          { ect: existing_ects, mentor: existing_mentors }.each do |type, existing_count|
            missing_count = [count - existing_count, 0].max
            next if missing_count.zero?

            missing_count.times do
              school_partnership = school_partnership(active_lead_provider)
              next unless school_partnership

              school = school_partnership.school
              start_date = Date.new(contract_period_year, 9, 1)
              finished_date = Date.current - rand(1..8).weeks

              school_period = FactoryBot.create(
                :"#{type}_at_school_period",
                school:,
                started_on: start_date,
                finished_on: finished_date
              )

              schedule = find_schedule(contract_period)

              FactoryBot.create(
                :training_period,
                :"for_#{type}",
                :provider_led,
                :active,
                "#{type}_at_school_period" => school_period,
                school_partnership:,
                schedule:,
                started_on: start_date,
                finished_on: finished_date
              )

              log_participant_created(
                type:,
                participant_status: "left",
                training_status: "active",
                contract_period_year:,
                lead_provider_name: active_lead_provider.lead_provider.name
              )
            end
          end
        end
      end
    end

    def school_partnership(active_lead_provider)
      SchoolPartnership
        .includes(:lead_provider_delivery_partnership)
        .where(lead_provider_delivery_partnership: { active_lead_provider: })
        .order("RANDOM()")
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
        .excluding_replacement_schedules
        .where(contract_period:)
        .order(Arel.sql("RANDOM()"))
        .first
    end

    def find_contract_period(year)
      ContractPeriod.find_by(year:)
    end

    def random_or_create_appropriate_body
      AppropriateBodyPeriod.order(Arel.sql("RANDOM()")).first ||
        FactoryBot.create(:appropriate_body)
    end

    def find_random_statement(active_lead_provider)
      ::Statements::Search.new(
        lead_provider_id: active_lead_provider.lead_provider.id,
        contract_period_years: active_lead_provider.contract_period_year,
        fee_type: "output"
      )
      .statements
      .sample
    end

    def declaration_date(schedule, declaration_type)
      milestone = schedule.milestones.find_by(declaration_type:)
      # Sometimes the milestone start_date is in the future; we will omit
      # these declarations in the calling method.
      end_date = [milestone&.start_date, 1.day.ago].compact.max

      return Faker::Date.between(from: Date.new(schedule.contract_period.year), to: end_date) unless milestone

      Faker::Date.between(from: milestone.start_date, to: milestone.milestone_date || end_date)
    end

    def log_participant_created(
      type:,
      participant_status:,
      training_status:,
      contract_period_year:,
      lead_provider_name:
    )
      log_message = <<~TXT.squish
        Created #{type} with participant status #{participant_status}
        and training status #{training_status}
        in contract period #{contract_period_year}
        with #{lead_provider_name}
      TXT

      log_seed_info(log_message, colour: Colourize::COLOURS.keys.sample)
    end
  end
end
