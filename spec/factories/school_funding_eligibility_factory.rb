FactoryBot.define do
  factory(:school_funding_eligibility) do
    association :gias_school
    association :contract_period

    pupil_premium_uplift { true }
    sparsity_uplift { true }
  end
end
