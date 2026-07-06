FactoryBot.define do
  factory(:statement) do
    transient do
      contract_period { create(:contract_period, :current) }
      active_lead_provider { association(:active_lead_provider, contract_period:) }

      month_year_pair do
        contract_year = active_lead_provider.contract_period.year
        last_year, last_month =
          Statement
            .joins(contract: :active_lead_provider)
            .where(contract: { active_lead_provider: })
            .order(year: :desc, month: :desc)
            .pick(:year, :month)

        # Advance 1 month from any existing statement, or default to November
        # of the contract year if there are no statements yet.
        date = Date.new(last_year || contract_year, last_month || 10, 1) >> 1

        { year: date.year, month: date.month }
      end
    end

    allow_creation_with_past_deadline_date { true }
    contract { association(:contract, :for_ittecf_ectp, active_lead_provider:) }
    api_id { SecureRandom.uuid }

    month { month_year_pair[:month] }
    year { month_year_pair[:year] }
    deadline_date { Date.new(year, month, 1).prev_day }
    payment_date do
      payment_month = deadline_date.next_month
      Date.new(payment_month.year, payment_month.month, 25)
    end
    output_fee

    trait :open do
      status { :open }
    end

    trait :payable do
      status { :payable }
      deadline_date { [Date.new(year, month, 1).prev_day, Date.yesterday].min }
    end

    trait :paid do
      status { :paid }
      deadline_date { [Date.new(year, month, 1).prev_day, Date.yesterday].min }
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
    end

    trait :paid_in_month do
      paid

      marked_as_paid_at do
        next_month = Date.new(year, month, 1).next_month
        Date.new(next_month.year, next_month.month, 26)
      end
    end
  end
end
