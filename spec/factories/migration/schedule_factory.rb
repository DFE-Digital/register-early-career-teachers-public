FactoryBot.define do
  factory :migration_schedule, class: "Migration::Schedule" do
    cohort { FactoryBot.create(:migration_cohort) }
    schedule_identifier { "#{Faker::Lorem.word} #{Faker::Alphanumeric.alpha(number: 5).upcase}" }
    name { Faker::Lorem.words(number: 2) }
  end
end
