module DeliveryPartners::API
  class Query < DeliveryPartners::Query
  protected

    def preload_associations(results)
      preloaded_results = results
        .strict_loading
        .includes(:lead_provider_metadata)

      unless ignore?(filter: lead_provider_id)
        preloaded_results = preloaded_results
          .references(:metadata_delivery_partners_lead_providers)
          .where(metadata_delivery_partners_lead_providers: { lead_provider_id: })
      end

      preloaded_results
    end
  end
end
