FactoryBot.define do
  factory(:school_contract_period_metadata, class: "Metadata::SchoolContractPeriod") do
    association :school
    association :contract_period

    updated_at { Faker::Time.between(from: 1.month.ago, to: Time.zone.now) }
    in_partnership { Faker::Boolean.boolean }
    induction_programme_choice { Metadata::SchoolContractPeriod.induction_programme_choices.keys.sample }
  end
end
