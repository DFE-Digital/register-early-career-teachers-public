FactoryBot.define do
  factory(:api_third_party, class: "API::ThirdParty") do
    initialize_with do
      API::ThirdParty.find_or_initialize_by(name:, email:)
    end

    sequence(:name) { |n| "Third-party #{n}" }
    email { "#{name.parameterize}@api" }
  end
end
