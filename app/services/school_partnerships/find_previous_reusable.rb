module SchoolPartnerships
  class FindPreviousReusable
    include ContractPeriodYearConcern

    # Returns SchoolPartnership or nil
    def call(school:, last_lead_provider:, current_contract_period:)
      return nil unless valid_params?(school, last_lead_provider, current_contract_period)

      current_year = to_year(current_contract_period)
      active_lead_provider = current_active_lead_provider_for(lead_provider: last_lead_provider, year: current_year)
      return nil unless active_lead_provider

      current_delivery_partner_ids = current_delivery_partner_ids_for(active_lead_provider:)
      return nil if current_delivery_partner_ids.empty?

      previous_scope = previous_partnerships_scope(
        school:,
        lead_provider: last_lead_provider,
        exclude_year: current_year
      )

      overlapping_scope = overlapping_delivery_partners_scope(previous_scope, current_delivery_partner_ids)
      ordered_scope = order_latest_year_then_newest_created(overlapping_scope)

      ordered_scope.first
    end

  private

    def valid_params?(school, lead_provider, current_contract_period)
      school.present? && lead_provider.present? && current_contract_period.present?
    end

    def current_active_lead_provider_for(lead_provider:, year:)
      ActiveLeadProvider
        .for_lead_provider(lead_provider.id)
        .for_contract_period_year(year)
        .take
    end

    def current_delivery_partner_ids_for(active_lead_provider:)
      LeadProviderDeliveryPartnership
        .where(active_lead_provider_id: active_lead_provider.id)
        .pluck(:delivery_partner_id)
    end

    def previous_partnerships_scope(school:, lead_provider:, exclude_year:)
      SchoolPartnerships::Search
        .new(school:, lead_provider:)
        .school_partnerships
        .excluding_contract_period_year(exclude_year)
        .latest_by_contract_year
    end

    def overlapping_delivery_partners_scope(base_scope, current_delivery_partner_ids)
      base_scope.where(
        lead_provider_delivery_partnership_id: LeadProviderDeliveryPartnership
          .where(delivery_partner_id: current_delivery_partner_ids)
          .select(:id)
      )
    end

    def order_latest_year_then_newest_created(base_scope)
      base_scope
        .reorder(nil)
        .joins(lead_provider_delivery_partnership: :active_lead_provider)
        .order("active_lead_providers.contract_period_year DESC")
        .order("school_partnerships.created_at DESC")
        .order("school_partnerships.id DESC")
    end
  end
end
