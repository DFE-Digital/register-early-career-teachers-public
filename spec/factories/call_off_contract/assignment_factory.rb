FactoryBot.define do
  factory(:call_off_contract_assignment, class: "CallOffContract::Assignment") do
    association :statement, factory: :statement

    trait :banded do
      association :call_off_contract, factory: :call_off_contract_banded
    end

    trait :flat_rate do
      association :call_off_contract, factory: :call_off_contract_flat_rate
    end
  end
end
