FactoryBot.define do
  factory(:lead_provider) do
    # Keep the default as a single word without spaces, or the
    # short_name will end up conflicting.
    sequence(:name) { |n| "LeadProvider#{n}" }
    ecf_id { SecureRandom.uuid }
    vat_registered { true }

    initialize_with do
      LeadProvider.find_or_initialize_by(name:)
    end
  end
end
