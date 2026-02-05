FactoryBot.define do
  factory :contract_banded_fee_structure, class: "Contract::BandedFeeStructure" do
    recruitment_target { 6000 }
    uplift_fee_per_declaration { 100 }
    monthly_service_fee { 123.45 }
    setup_fee { 149_651 }
  end
end
