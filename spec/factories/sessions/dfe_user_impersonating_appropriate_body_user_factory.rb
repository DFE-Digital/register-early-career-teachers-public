FactoryBot.define do
  factory(:dfe_user_impersonating_appropriate_body_user, class: "Sessions::Users::DfEUserImpersonatingAppropriateBodyUser") do
    skip_create
    initialize_with { new(email:, appropriate_body_period_id:, original_type: "Sessions::DfEUser") }

    appropriate_body_period_id { nil }

    trait(:at_random_organisation) do
      appropriate_body_period_id do
        FactoryBot.create(:appropriate_body_period).id
      end
    end
  end
end
