FactoryBot.define do
  factory(:local_authority) do
    initialize_with do
      LocalAuthority.find_or_initialize_by(name:)
    end

    sequence(:name) { |n| "Local Authority #{n}" }
  end
end
