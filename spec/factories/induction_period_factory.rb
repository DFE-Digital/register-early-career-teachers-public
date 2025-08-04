FactoryBot.define do
  factory(:induction_period) do
    association :appropriate_body
    association :teacher

    started_on { 1.year.ago }
    finished_on { 1.month.ago }
    number_of_terms { 1 }
    induction_programme { "fip" }
    training_programme { 'provider_led' }

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
  end
end
