FactoryBot.define do
  factory :migration_participant_identity, class: "Migration::ParticipantIdentity" do
    user { FactoryBot.create(:migration_user) }
    email { user.email }
    external_identifier { user.id }
    origin { "ecf" }
  end
end
