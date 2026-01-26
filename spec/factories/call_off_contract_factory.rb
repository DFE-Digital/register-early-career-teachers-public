FactoryBot.define do
  factory(:call_off_contract, class: "CallOffContract") do
    recruitment_target { 1_000 }

    trait :banded do
      association :contractable, factory: :call_off_contract_banded
    end

    trait :flat_rate do
      association :contractable, factory: :call_off_contract_flat_rate
    end
  end
end
