FactoryBot.define do
  factory(:parity_check_response, class: "ParityCheck::Response") do
    association(:request, factory: :parity_check_request)
    ecf_body { "ECF response body" }
    ecf_status_code { 200 }
    ecf_time_ms { Faker::Number.between(from: 10, to: 2000) }
    rect_body { "RECT response body" }
    rect_status_code { 201 }
    rect_time_ms { Faker::Number.between(from: 10, to: 2000) }

    trait :matching do
      ecf_status_code { 200 }
      rect_status_code { 200 }
      ecf_body { "Same response body" }
      rect_body { "Same response body" }
    end

    trait :different do
      ecf_status_code { 200 }
      rect_status_code { 201 }
      ecf_body { "ECF response body" }
      rect_body { "RECT response body" }
    end
  end
end
