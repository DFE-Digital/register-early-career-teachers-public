FactoryBot.define do
  factory :migration_schedule, class: "Migration::Schedule" do
    cohort { FactoryBot.create(:migration_cohort) }
    schedule_identifier do
      %w[
        ecf-standard-september
        ecf-standard-january
        ecf-standard-april
        ecf-extended-september
        ecf-extended-january
        ecf-extended-april
        ecf-reduced-september
        ecf-reduced-january
        ecf-reduced-april
      ].sample
    end
    name { Faker::Lorem.words(number: 2) }

    trait :replacement do
      schedule_identifier do
        %w[
          ecf-replacement-september
          ecf-replacement-january
          ecf-replacement-april
        ].sample
      end
    end
  end
end
