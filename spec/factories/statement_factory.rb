FactoryBot.define do
  factory(:statement) do
    transient do
      contract_period { FactoryBot.create(:contract_period) }
      active_lead_provider { association(:active_lead_provider, contract_period:) }

      month_year_pair do
        # Statements start in November of the contract year and run to August 3 years ahead
        # e.g. for 2021 cohort: November 2021 through to August 2024
        contract_year = contract.active_lead_provider.contract_period.year
        start_date = Date.new(contract_year, 11, 1)

        # Offset by the number of existing statements for this active_lead_provider
        # so each factory call produces a unique month/year pair
        existing_count = Statement
          .joins(:contract)
          .where(contracts: { active_lead_provider_id: active_lead_provider.id })
          .count

        month = start_date >> existing_count
        { year: month.year, month: month.month }
      end
    end

    contract { association(:contract, :for_ittecf_ectp, active_lead_provider:) }
    api_id { SecureRandom.uuid }

    month { month_year_pair[:month] }
    year { month_year_pair[:year] }
    deadline_date { Date.new(year, month, 1).prev_day }
    payment_date { Date.new(year, month, 25) }
    output_fee

    initialize_with do
      Statement
        .joins(:contract)
        .where(contracts: { active_lead_provider_id: active_lead_provider.id })
        .find_or_initialize_by(
          month:,
          year:
        ) do |statement|
          statement.contract = contract
        end
    end

    trait :open do
      status { :open }
    end

    trait :payable do
      status { :payable }
    end

    trait :paid do
      status { :paid }
    end

    trait :output_fee do
      fee_type { "output" }
    end

    trait :service_fee do
      fee_type { "service" }
    end

    trait :adjustable do
      open
      output_fee

      deadline_date { Date.new(year, month, 1) }
      payment_date { Date.new(year, month, 25) }
    end

    trait :paid_in_month do
      paid

      deadline_date { Date.new(year, month, 1).prev_day }
      payment_date  { Date.new(year, month, 25) }

      marked_as_paid_at do
        next_month = Date.new(year, month, 1).next_month
        Date.new(next_month.year, next_month.month, 26)
      end
    end
  end
end
