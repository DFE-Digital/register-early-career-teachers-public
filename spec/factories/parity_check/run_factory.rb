FactoryBot.define do
  factory(:parity_check_run, class: "ParityCheck::Run") do
    transient do
      request_states { [] }
    end

    after(:build) do |run, evaluator|
      run.requests = evaluator.request_states.map { build(:parity_check_request, it, run:) } if evaluator.request_states.any?
    end

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
