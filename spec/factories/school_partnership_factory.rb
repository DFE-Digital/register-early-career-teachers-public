FactoryBot.define do
  factory(:school_partnership) do
    association :delivery_partner
    association :available_provider_pairing
  end
end
