FactoryBot.define do
  factory(:pupil_premium) do
    association :school
    association :contract_period

    pupil_premium_uplift { true }
    sparsity_uplift { true }
  end
end
