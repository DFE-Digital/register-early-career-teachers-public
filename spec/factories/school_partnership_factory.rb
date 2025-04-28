FactoryBot.define do
  factory(:school_partnership) do
    association :registration_period
    association :lead_provider
    association :delivery_partner
    association :school
  end
end
