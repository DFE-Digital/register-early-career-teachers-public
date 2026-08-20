FactoryBot.define do
  factory :framework_agreement_band, class: "FrameworkAgreement::Band" do
    association :framework_agreement
    capacity { 100 }

    allow_creation_when_contracted_or_after_contract_period_start { true }
  end
end
