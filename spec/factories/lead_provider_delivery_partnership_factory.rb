FactoryBot.define do
  factory(:lead_provider_delivery_partnership) do
    association :active_lead_provider
    association :delivery_partner

    trait :with_delivery_partner_metadata do
      delivery_partner do
        lead_provider = active_lead_provider.lead_provider

        association :delivery_partner, :with_metadata, lead_provider:
      end
    end
  end
end
