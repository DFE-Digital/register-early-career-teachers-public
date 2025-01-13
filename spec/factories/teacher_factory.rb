FactoryBot.define do
  factory(:teacher) do
    sequence(:trn, 1_000_000)
    first_name { Faker::Name.name }
    last_name { Faker::Name.last_name }

    trait :with_corrected_name do
      corrected_name { [first_name, Faker::Name.middle_name, last_name].join(' ') }
    end
  end
end
