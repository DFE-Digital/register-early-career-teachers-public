FactoryBot.define do
  factory(:dfe_sign_in_role) do
    code { DfESignInRole.codes.keys.sample }
    dfe_sign_in_role_id { Faker::Internet.uuid }
  end
end
