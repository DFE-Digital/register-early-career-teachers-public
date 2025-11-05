FactoryBot.define do
  factory(:teaching_school_hub) do
    name { Faker::Company.name }
    association :dfe_sign_in_organisation
    lead_school { association :school }
  end
end
