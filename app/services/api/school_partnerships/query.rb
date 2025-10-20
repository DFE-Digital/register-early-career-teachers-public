module API::SchoolPartnerships
  class Query
    include Queries::FilterIgnorable

    attr_reader :scope

    def initialize(school_id: :ignore, contract_period_years: :ignore, lead_provider_id: :ignore, delivery_partner_api_ids: :ignore, updated_since: :ignore, sort: {created_at: :asc})
      @scope = SchoolPartnership

      where_lead_provider_is(lead_provider_id)
      where_contract_period_year_in(contract_period_years)
      where_school_is(school_id)
      where_delivery_partner_is(delivery_partner_api_ids)
      where_updated_since(updated_since)
      set_sort_by(sort)
    end

    delegate(:exists?, to: :scope)

    def school_partnerships
      preload_associations(block_given? ? yield(scope) : scope)
    end

    def school_partnership_by_api_id(api_id)
      return preload_associations(scope).find_by!(api_id:) if api_id.present?

      fail(ArgumentError, "api_id needed")
    end

    def school_partnership_by_id(id)
      return preload_associations(scope).find(id) if id.present?

      fail(ArgumentError, "id needed")
    end

    private

    def preload_associations(results)
      results
        .strict_loading
        .includes(:delivery_partner, :active_lead_provider, :ongoing_training_periods, school: :gias_school)
    end

    def where_lead_provider_is(lead_provider_id)
      return if ignore?(filter: lead_provider_id)

      @scope = scope
        .joins(:active_lead_provider)
        .where(
          lead_provider_delivery_partnership: {active_lead_providers: {lead_provider_id:}}
        )
    end

    def where_contract_period_year_in(contract_period_years)
      return if ignore?(filter: contract_period_years)

      @scope = scope
        .joins(:active_lead_provider)
        .where(
          lead_provider_delivery_partnership: {active_lead_providers: {contract_period_year: contract_period_years}}
        )
    end

    def where_school_is(school_id)
      return if ignore?(filter: school_id)

      @scope = scope.where(school_id:)
    end

    def where_delivery_partner_is(delivery_partner_api_ids)
      return if ignore?(filter: delivery_partner_api_ids)

      @scope = scope
        .joins(:delivery_partner)
        .where(
          lead_provider_delivery_partnership: {delivery_partners: {api_id: delivery_partner_api_ids}}
        )
    end

    def where_updated_since(updated_since)
      return if ignore?(filter: updated_since)

      @scope = scope.where(api_updated_at: updated_since..)
    end

    def set_sort_by(sort)
      @scope = scope.order(sort)
    end
  end
end
