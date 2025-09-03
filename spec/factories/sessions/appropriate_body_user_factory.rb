FactoryBot.define do
  factory(:appropriate_body_user, class: 'Sessions::Users::AppropriateBodyUser') do
    skip_create
    initialize_with { new(email:, name:, dfe_sign_in_organisation_id:, dfe_sign_in_user_id:) }

    sequence(:email) { |n| "user@ab#{n}.com" }
    sequence(:name) { |n| "User at Appropriate Body #{n}" }

    dfe_sign_in_organisation_id { SecureRandom.uuid }
    dfe_sign_in_user_id { SecureRandom.uuid }

    trait(:at_random_appropriate_body) do
      dfe_sign_in_organisation_id { FactoryBot.create(:appropriate_body).dfe_sign_in_organisation_id }
    end
  end
end
