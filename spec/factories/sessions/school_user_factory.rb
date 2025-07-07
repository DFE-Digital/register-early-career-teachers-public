FactoryBot.define do
  factory(:school_user, class: 'Sessions::Users::SchoolUser') do
    skip_create
    initialize_with { new(email:, name:, school_urn:, dfe_sign_in_organisation_id:, dfe_sign_in_user_id:) }

    sequence(:email) { |n| "school.user@school#{n}.com" }
    sequence(:name) { |n| "Teacher at School #{n}" }

    dfe_sign_in_organisation_id { SecureRandom.uuid }
    dfe_sign_in_user_id { SecureRandom.uuid }

    # NOTE: school_urn is required, either pass one in or use :at_random_school or this
    #       will fail
    school_urn { nil }
    trait(:at_random_school) { school_urn { create(:school).urn } }
  end
end
