FactoryBot.define do
  factory(:parity_check_run, class: "ParityCheck::Run") do
    trait :concurrent do
      mode { :concurrent }
    end

    trait :sequential do
      mode { :sequential }
    end

    trait :pending do
      state { :pending }
    end

    trait :in_progress do
      state { :in_progress }
      started_at { Time.current }
    end

    trait :completed do
      state { :completed }
      started_at { Time.current }
      completed_at { Time.current + 3.minutes }
    end
  end
end
