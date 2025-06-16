FactoryBot.define do
  factory(:parity_check_endpoint, class: "ParityCheck::Endpoint") do
    add_attribute(:method) { :get }
    path { "/test-path" }
    options { { foo: :bar } }
  end
end
