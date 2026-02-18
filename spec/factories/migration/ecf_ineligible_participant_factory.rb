FactoryBot.define do
  factory :migration_ecf_ineligible_participant, class: "Migration::ECFIneligibleParticipant" do
    trn { Faker::Number.unique.number(digits: 7) }
    reason { "previous_participation" }
  end
end
