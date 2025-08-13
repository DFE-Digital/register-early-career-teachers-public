FactoryBot.define do
  factory(:lead_provider_delivery_partnership) do
    transient do
      contract_year { Random.rand(2021..2120) }
    end

    active_lead_provider do
      FactoryBot.create(:active_lead_provider, contract_period: (ContractPeriod.find_by(year: contract_year) || FactoryBot.create(:contract_period, year: contract_year)))
    end

    association :delivery_partner
  end
end
