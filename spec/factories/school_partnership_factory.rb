FactoryBot.define do
  factory(:school_partnership) do
    transient do
      contract_year { Random.rand(2021..2120) }
    end

    lead_provider_delivery_partnership { FactoryBot.create(:lead_provider_delivery_partnership, contract_year:) }
    association :school
  end
end
