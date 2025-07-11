module SchoolPartnerships
  class Query
    attr_reader :scope

    def initialize(school: :ignore, contract_period: :ignore, lead_provider: :ignore, delivery_partner: :ignore)
      @scope = default_scope

      where_lead_provider(lead_provider)
      where_contract_period(contract_period)
      where_school(school)
      where_delivery_partner(delivery_partner)
    end

    delegate(:exists?, to: :scope)

    def school_partnerships
      scope.earliest_first
    end

    def earliest_school_partnership
      school_partnerships.first
    end

  private

    def where_lead_provider(lead_provider)
      return if lead_provider == :ignore

      scope.merge!(
        scope.where(
          lead_provider_delivery_partnership: { active_lead_providers: { lead_provider: } }
        )
      )
    end

    def where_contract_period(contract_period)
      return if contract_period == :ignore

      scope.merge!(
        scope.where(
          lead_provider_delivery_partnership: { active_lead_providers: { contract_period: } }
        )
      )
    end

    def where_school(school)
      return if school == :ignore

      scope.merge!(scope.where(school:))
    end

    def where_delivery_partner(delivery_partner)
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
          lead_provider_delivery_partnership: [
            :delivery_partner,
            { active_lead_provider: %i[lead_provider contract_period] }
          ]
        )
    end
  end
end
