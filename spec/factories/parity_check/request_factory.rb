FactoryBot.define do
  factory(:parity_check_request, class: "ParityCheck::Request") do
    association(:lead_provider)
    association(:run, factory: :parity_check_run)
    association(:endpoint, factory: :parity_check_endpoint)

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
    end
  end
end
