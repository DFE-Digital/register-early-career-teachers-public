module Builders
  module BuilderHelpers
    def find_school_partnership!(training_period_data, school)
      lead_provider = CacheManager.instance.find_lead_provider_by_name(training_period_data.lead_provider)
      raise(ActiveRecord::RecordNotFound, "Couldn't find LeadProvider with name #{training_period_data.lead_provider}") unless lead_provider

      active_lead_provider = CacheManager.instance.find_active_lead_provider(lead_provider_id: lead_provider.id, contract_period_year: training_period_data.cohort_year)
      raise(ActiveRecord::RecordNotFound, "Couldn't find ActiveLeadProvider with lead_provider_id #{lead_provider.id} and contract_period_year #{training_period_data.cohort_year}") unless active_lead_provider

      delivery_partner = CacheManager.instance.find_delivery_partner_by_name(training_period_data.delivery_partner)
      raise(ActiveRecord::RecordNotFound, "Couldn't find DeliveryPartner with name #{training_period_data.delivery_partner}") unless delivery_partner

      lead_provider_delivery_partnership = CacheManager.instance.find_lead_provider_delivery_partnership_by_key(active_lead_provider_id: active_lead_provider.id, delivery_partner_id: delivery_partner.id)
      raise(ActiveRecord::RecordNotFound, "Couldn't find LeadProviderDeliveryPartnership with active_lead_provider_id #{active_lead_provider.id} and delivery_partner_id #{delivery_partner.id}") unless lead_provider_delivery_partnership

      school_partnership = CacheManager.instance.find_school_partnership(lead_provider_delivery_partnership_id: lead_provider_delivery_partnership.id, school_id: school.id)
      raise(ActiveRecord::RecordNotFound, "Couldn't find SchoolPartnership with lead_provider_delivery_partnership_id #{lead_provider_delivery_partnership.id} and school_id #{school.id}") unless school_partnership

      school_partnership
    end
  end
end
