module Builders
  module BuilderHelpers
    def find_school_partnership!(training_period_data, school)
      lead_provider = ::LeadProvider.find_by!(name: training_period_data.lead_provider)
      active_lead_provider = ::ActiveLeadProvider.find_by!(lead_provider:, contract_period_year: training_period_data.cohort_year)
      delivery_partner = ::DeliveryPartner.find_by!(name: training_period_data.delivery_partner)
      lead_provider_delivery_partnership = ::LeadProviderDeliveryPartnership.find_by!(active_lead_provider:, delivery_partner:)
      ::SchoolPartnership.find_by!(lead_provider_delivery_partnership:, school:)
    end
  end
end
