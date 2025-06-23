FactoryBot.define do
  factory(:parity_check_endpoint, class: "ParityCheck::Endpoint") do
    add_attribute(:method) { :get }
    path { "/test-path" }
    options { { foo: :bar } }

    trait :get do
      add_attribute(:method) { :get }
    end

    trait :post do
      add_attribute(:method) { :post }
      options { { body: :example_statement_body } }
    end

    trait :put do
      add_attribute(:method) { :post }
      options { { body: :example_statement_body } }
    end

    trait :with_query_parameters do
      options { { query: { filter: "value" } } }
    end

    trait :with_pagination do
      options { { paginate: true } }
    end

    trait :with_query_parameters_and_pagination do
      options { { paginate: true, query: { filter: "value" } } }
    end
  end
end
