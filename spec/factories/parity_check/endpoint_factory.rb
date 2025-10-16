FactoryBot.define do
  factory(:parity_check_endpoint, class: "ParityCheck::Endpoint") do
    add_attribute(:method) { :get }
    path { "/test-path" }
    options { {foo: :bar} }

    trait :get do
      add_attribute(:method) { :get }
    end

    trait :post do
      add_attribute(:method) { :post }
      options { {body: :partnership_create_body} }
    end

    trait :put do
      add_attribute(:method) { :put }
      options { {body: :partnership_update_body} }
    end

    trait :with_query_parameters do
      options { {query: {filter: {key: "value"}}} }
    end

    trait :with_pagination do
      options { {paginate: true} }
    end

    trait :with_query_parameters_and_pagination do
      options { {paginate: true, query: {filter: {key: "value"}}} }
    end
  end
end
