FactoryBot.define do
  factory(:teaching_school_hub) do
    initialize_with do
      TeachingSchoolHub.find_or_initialize_by(name:)
    end

    name { Faker::Company.name }
    association :dfe_sign_in_organisation
    lead_school { association :school }
  end
end
