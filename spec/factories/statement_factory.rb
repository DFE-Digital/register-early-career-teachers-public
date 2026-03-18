FactoryBot.define do
  factory(:statement) do
    transient do
      contract_period { FactoryBot.create(:contract_period) }
      active_lead_provider { association(:active_lead_provider, contract_period:) }
    end

    contract { association(:contract, :for_ittecf_ectp, active_lead_provider:) }
    api_id { SecureRandom.uuid }

    transient do
      sequence(:statement_month_offset) { |n| n - 1 }
    end

    month { (statement_month_offset % 12) + 1 }
    year { contract.active_lead_provider.contract_period.year + 1 + (statement_month_offset / 12) }
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
