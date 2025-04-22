FactoryBot.define do
  factory(:school_partnership) do
    association :lead_provider_delivery_partnership
    association :school
  end
end
