FactoryBot.define do
  factory(:lead_provider) do
    sequence(:name) { |n| "Lead Provider #{n}" }
    ecf_id { SecureRandom.uuid }

    initialize_with do
      LeadProvider.find_or_initialize_by(name:)
    end
  end
end
