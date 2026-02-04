FactoryBot.define do
  factory(:appropriate_body_user, class: "Sessions::Users::AppropriateBodyUser") do
    skip_create
    initialize_with { new(email:, name:, dfe_sign_in_organisation_id:, dfe_sign_in_user_id:, dfe_sign_in_roles:) }

    sequence(:email) { |n| "user@ab#{n}.com" }
    sequence(:name) { |n| "User at Appropriate Body #{n}" }

    dfe_sign_in_organisation_id { SecureRandom.uuid }
    dfe_sign_in_user_id { SecureRandom.uuid }
    dfe_sign_in_roles { %w[AppropriateBodyUser] }

    trait(:at_random_appropriate_body) do
      dfe_sign_in_organisation_id { FactoryBot.create(:appropriate_body_period).dfe_sign_in_organisation_id }
    end
  end
end
