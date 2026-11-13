namespace :product_review do
  desc "Set up nine ECT contract period registration scenarios (#4620)"
  task "4620" => :environment do
    abort("Only available in development and review environments") unless Rails.env.development? || Rails.env.review?

    brookfield = School.find_by!(urn: 2_976_163)
    ackley_bridge = School.find_by!(urn: 3_375_958)
    abbey_grove = School.find_by!(urn: 1_759_427)
    coal_hill = School.find_by!(urn: 3_583_173)
    grange_hill = School.find_by!(urn: 2_472_261)
    greyfriars = School.find_by!(urn: 6_384_201)

    teach_first = LeadProvider.find_by!(name: "Teach First")
    ambition_institute = LeadProvider.find_by!(name: "Ambition Institute")
    capita = LeadProvider.find_by!(name: "Capita")

    appropriate_body = AppropriateBodyPeriod.active.find_by!(
      name: "Bright Futures Teaching School Hub (Salford & Trafford)"
    )

    contract_periods = [2022, 2023, 2024, 2025, 2026].index_with do |year|
      ContractPeriod.find_by!(year:)
    end

    unless contract_periods.fetch(2022).payments_frozen?
      abort("The 2022 contract period must have payments frozen")
    end

    if [2024, 2025].any? { |year| contract_periods.fetch(year).payments_frozen? }
      abort("The 2024 and 2025 contract periods must be eligible to carry forward")
    end

    agreements = contract_periods.transform_values do |contract_period|
      FrameworkAgreement.find_by!(
        lead_provider: teach_first,
        contract_period:
      )
    end

    schedules = contract_periods.transform_values do |contract_period|
      Schedule.find_by!(
        contract_period:,
        identifier: "ecf-standard-september"
      )
    end

    ambition_agreement = FrameworkAgreement.find_by!(
      lead_provider: ambition_institute,
      contract_period: contract_periods.fetch(2024)
    )

    partnership_scope = SchoolPartnership.joins(
      :lead_provider_delivery_partnership
    )

    brookfield_partnership = partnership_scope.find_by!(
      school: brookfield,
      lead_provider_delivery_partnerships: {
        framework_agreement_id: agreements.fetch(2024).id
      }
    )

    [2024, 2025].each do |year|
      partnership_scope.find_by!(
        school: abbey_grove,
        lead_provider_delivery_partnerships: {
          framework_agreement_id: agreements.fetch(year).id
        }
      )
    end

    if partnership_scope.exists?(
      school: grange_hill,
      lead_provider_delivery_partnerships: {
        framework_agreement_id: ambition_agreement.id
      }
    )
      abort("Cannot set up Ditto's EOI test: Grange Hill already has a 2024 Ambition Institute partnership.")
    end

    if FrameworkAgreement.exists?(
      lead_provider: capita,
      contract_period: contract_periods.fetch(2024)
    )
      abort("Cannot set up the provider-reuse test: Capita already has a 2024 framework agreement.")
    end

    provider_led_2024 = {
      school: brookfield,
      started_on: Date.new(2024, 9, 1),
      finished_on: Date.new(2025, 8, 31),
      contract_year: 2024
    }

    school_led_2025 = {
      school: ackley_bridge,
      started_on: Date.new(2025, 9, 1),
      finished_on: Date.new(2026, 8, 31)
    }

    frozen_history = [
      {
        school: brookfield,
        started_on: Date.new(2022, 9, 1),
        finished_on: Date.new(2023, 8, 31),
        contract_year: 2022
      },
      {
        school: ackley_bridge,
        started_on: Date.new(2023, 9, 1),
        finished_on: Date.new(2026, 8, 31)
      }
    ]

    scenarios = [
      # 1. PL (2024) -> SL -> PL, matching partnership.
      {
        trn: "3012247",
        first_name: "Butterfree",
        last_name: "Barnaby",
        no_qts: true,
        periods: [
          provider_led_2024.merge(
            school_partnership: brookfield_partnership
          ),
          school_led_2025
        ]
      },

      # 2. PL (2024) -> SL -> PL, expression of interest fallback.
      {
        trn: "3012246",
        first_name: "Ditto",
        last_name: "Debbie",
        no_qts: true,
        periods: [
          provider_led_2024.merge(
            expression_of_interest: ambition_agreement
          ),
          school_led_2025
        ]
      },

      # 3. PL (2024) -> SL -> SL -> PL.
      {
        trn: "3002582",
        first_name: "Robson",
        last_name: "Scottie",
        periods: [
          provider_led_2024.merge(
            school_partnership: brookfield_partnership
          ),
          school_led_2025.merge(
            finished_on: Date.new(2026, 3, 31)
          ),
          {
            school: coal_hill,
            started_on: Date.new(2026, 4, 1),
            finished_on: Date.new(2026, 8, 31)
          }
        ]
      },

      # 4. PL (frozen 2022) -> SL -> PL (reassigned to 2024).
      {
        trn: "3012245",
        first_name: "Squirtle",
        last_name: "Samuels",
        no_qts: true,
        periods: frozen_history
      },

      # 5. PL (2023) -> SL -> PL (2025) -> PL, retain 2025.
      {
        trn: "3012243",
        first_name: "Clefairy",
        last_name: "Cuddles",
        no_qts: true,
        periods: [
          {
            school: brookfield,
            started_on: Date.new(2023, 9, 1),
            finished_on: Date.new(2024, 8, 31),
            contract_year: 2023
          },
          {
            school: ackley_bridge,
            started_on: Date.new(2024, 9, 1),
            finished_on: Date.new(2025, 8, 31)
          },
          {
            school: coal_hill,
            started_on: Date.new(2025, 9, 1),
            finished_on: Date.new(2026, 8, 31),
            contract_year: 2025
          }
        ]
      },

      # 6. SL -> PL, use the registration year.
      {
        trn: "3002577",
        first_name: "Jonas",
        last_name: "Bloggs",
        periods: [school_led_2025]
      },

      # 7. PL -> PL, previous PL starts on the reported school start date.
      {
        trn: "3002578",
        first_name: "Cynthia",
        last_name: "Parks",
        periods: [
          provider_led_2024.merge(
            finished_on: nil,
            training_started_on: Date.new(2026, 9, 1)
          )
        ]
      },

      # 8. PL -> PL, previous PL starts after the reported school start date.
      {
        trn: "3012242",
        first_name: "Jigglypuff",
        last_name: "Jewels",
        no_qts: true,
        periods: [
          provider_led_2024.merge(
            finished_on: nil,
            training_started_on: Date.new(2026, 9, 2)
          )
        ]
      },

      # 9. PL (frozen 2022, provider A) -> SL -> PL.
      # Greyfriars last chose provider B, which has no 2024 agreement.
      {
        trn: "3012241",
        first_name: "Ash",
        last_name: "Ketchum",
        no_qts: true,
        periods: frozen_history,
        configure_reuse_school: true
      }
    ]

    created_count = 0
    skipped_count = 0

    ApplicationRecord.transaction do
      scenarios.each do |scenario|
        first_started_on = scenario.fetch(:periods).first.fetch(:started_on)

        teacher = Teacher.find_or_create_by!(trn: scenario.fetch(:trn)) do |record|
          record.trs_first_name = scenario.fetch(:first_name)
          record.trs_last_name = scenario.fetch(:last_name)

          unless scenario[:no_qts]
            record.trs_qts_awarded_on = Date.new(first_started_on.year, 7, 1)
            record.trs_induction_status = "RequiredToComplete"
          end
        end

        teacher.lock!

        if teacher.ect_at_school_periods.exists?
          skipped_count += 1
          next
        end

        if scenario[:configure_reuse_school]
          greyfriars.update!(
            last_chosen_appropriate_body: appropriate_body,
            last_chosen_training_programme: "provider_led",
            last_chosen_lead_provider: capita
          )
        end

        scenario.fetch(:periods).each do |period|
          school_period = teacher.ect_at_school_periods.create!(
            school: period.fetch(:school),
            started_on: period.fetch(:started_on),
            finished_on: period.fetch(:finished_on)
          )

          training_attributes = {
            started_on: period.fetch(
              :training_started_on,
              school_period.started_on
            ),
            finished_on: school_period.finished_on
          }

          if period[:contract_year]
            year = period.fetch(:contract_year)

            training_attributes.merge!(
              training_programme: "provider_led",
              schedule: schedules.fetch(year),
              school_partnership: period[:school_partnership],
              expression_of_interest: period.fetch(:expression_of_interest) do
                agreements.fetch(year) unless period[:school_partnership]
              end
            )
          else
            training_attributes[:training_programme] = "school_led"
          end

          school_period.training_periods.create!(training_attributes)
        end

        created_count += 1
      end
    end

    puts "Created #{created_count} scenarios; skipped #{skipped_count} teachers with existing ECT school history (#4620)."
  end
end
