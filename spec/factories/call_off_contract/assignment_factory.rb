FactoryBot.define do
  factory(:call_off_contract_assignment, class: "CallOffContract::Assignment") do
    association :statement, factory: :statement
    declaration_resolver_type { %i[all ect mentor].sample }

    trait :flat_rate do
      association :call_off_contract_flat_rate, factory: :call_off_contract_flat_rate
    end

    trait :banded do
      association :call_off_contract_banded, factory: :call_off_contract_banded
    end
  end
end
