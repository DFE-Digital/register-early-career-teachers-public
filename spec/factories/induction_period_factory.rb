FactoryBot.define do
  factory(:induction_period) do
    association :appropriate_body_period
    association :teacher

    started_on { 1.year.ago }
    finished_on { 1.month.ago }
    number_of_terms { 1 }
    induction_programme { "fip" }
    training_programme { "provider_led" }

    trait :ongoing do
      finished_on { nil }
      number_of_terms { nil }
    end

    trait :pass do
      outcome { :pass }
    end

    trait :fail do
      outcome { :fail }
    end

    trait(:cip) { induction_programme { "cip" } }
    trait(:diy) { induction_programme { "diy" } }
    trait(:pre_2021) { induction_programme { "pre_september_2021" } }

    trait :legacy_programme_type do
      after(:build) do |ip, evaluator|
        ip.write_attribute(:training_programme, nil)
        ip.write_attribute(:induction_programme, evaluator.induction_programme)
        ip.save!
      end
    end
  end
end
