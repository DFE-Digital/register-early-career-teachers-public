FactoryBot.define do
  factory(:parity_check_request, class: "ParityCheck::Request") do
    association(:lead_provider)
    association(:run, factory: :parity_check_run)
    association(:endpoint, factory: :parity_check_endpoint)

    transient do
      response_types { [] }
    end

    after(:build) do |request, evaluator|
      request.responses = evaluator.response_types.map { build(:parity_check_response, it, request:) } if evaluator.response_types.any?
    end

    trait :get do
      endpoint { association(:parity_check_endpoint, :get) }
    end

    trait :post do
      endpoint { association(:parity_check_endpoint, :post) }
    end

    trait :put do
      endpoint { association(:parity_check_endpoint, :put) }
    end

    trait :pending do
      state { :pending }
    end

    trait :queued do
      state { :queued }
    end

    trait :in_progress do
      state { :in_progress }
      started_at { Time.current }
    end

    trait :completed do
      state { :completed }
      started_at { Time.current }
      completed_at { Time.current + 3.minutes }
      response_types { %i[different] }
    end

    trait :completed_different do
      completed
      response_types { %i[different] }
    end

    trait :completed_matching do
      completed
      response_types { %i[matching] }
    end
  end
end
