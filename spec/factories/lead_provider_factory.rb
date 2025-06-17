FactoryBot.define do
  factory(:lead_provider) do
    sequence(:name) { |n| "Lead Provider #{n}" }
    ecf_id { SecureRandom.uuid }
  end
end
