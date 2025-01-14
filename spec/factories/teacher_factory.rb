FactoryBot.define do
  factory(:teacher) do
    sequence(:trn, 1_000_000)
    trs_first_name { Faker::Name.name }
    trs_last_name { Faker::Name.last_name }

    trait :with_corrected_name do
      corrected_name { [trs_first_name, Faker::Name.middle_name, trs_last_name].join(' ') }
    end
  end
end
