FactoryBot.define do
  factory(:dfe_user_impersonating_school_user, class: "Sessions::Users::DfEUserImpersonatingSchoolUser") do
    skip_create
    initialize_with { new(email:, school_urn:, original_type: "Sessions::DfEUser") }

    school_urn { nil }
    trait(:at_random_school) { school_urn { FactoryBot.create(:school).urn } }
  end
end
