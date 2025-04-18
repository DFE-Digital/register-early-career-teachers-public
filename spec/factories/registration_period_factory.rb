FactoryBot.define do
  sequence(:base_registration_period, 2021)

  factory(:registration_period) do
    year { generate(:base_registration_period) }

    started_on { Date.new(year, 6, 1) }
    finished_on { Date.new(year.next, 5, 31) }
  end
end
