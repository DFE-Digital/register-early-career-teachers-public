module SchoolPartnerships
  class Search
    attr_reader :scope

    def initialize(school: :ignore, contract_period: :ignore, lead_provider: :ignore, delivery_partner: :ignore)
      @scope = default_scope

      where_lead_provider_is(lead_provider)
      where_contract_period_year_in(contract_period)
      where_school_is(school)
      where_delivery_partner_is(delivery_partner)
    end

    delegate(:exists?, to: :scope)

    def school_partnerships
      scope.earliest_first
    end

  private

    def where_lead_provider_is(lead_provider)
      return if lead_provider == :ignore

      scope.merge!(
        scope.where(
          lead_provider_delivery_partnership: { active_lead_providers: { lead_provider: } }
        )
      )
    end

    def where_contract_period_year_in(contract_period)
      return if contract_period == :ignore

      scope.merge!(
        scope.where(
          lead_provider_delivery_partnership: { active_lead_providers: { contract_period_year: contract_period } }
        )
      )
    end

    def where_school_is(school)
      return if school == :ignore

      scope.merge!(scope.where(school:))
    end

    def where_delivery_partner_is(delivery_partner)
      return if delivery_partner == :ignore

      scope.merge!(
        scope.where(
          lead_provider_delivery_partnership: { delivery_partner: }
        )
      )
    end

    def default_scope
      SchoolPartnership
        .eager_load(
          :delivery_partner,
          school: :gias_school,
          active_lead_provider: :lead_provider
        )
    end
  end
end
