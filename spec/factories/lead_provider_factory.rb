FactoryBot.define do
  factory(:lead_provider) do
    sequence(:name) { |n| "Lead Provider #{n}" }
    sequence(:short_name) { |n| "lp#{n}" }
    ecf_id { SecureRandom.uuid }
    vat_registered { true }

    initialize_with do
      LeadProvider.find_or_initialize_by(name:)
    end
  end
end
