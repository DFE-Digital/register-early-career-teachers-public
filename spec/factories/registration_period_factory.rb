FactoryBot.define do
  sequence(:base_registration_period, 2021)

  factory(:registration_period) do
    year { generate(:base_registration_period) }
  end
end
