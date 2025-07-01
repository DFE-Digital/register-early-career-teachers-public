module SchoolPartnerships
  class Query
    def initialize(school: :ignore, registration_period: :ignore, lead_provider: :ignore, delivery_partner: :ignore)
      where_lead_provider(lead_provider)
      where_registration_period(registration_period)
      where_school(school)
      where_delivery_partner(delivery_partner)
    end

    delegate(:exists?, to: :scope)

  private

    def where_lead_provider(lead_provider)
      return if lead_provider == :ignore

      scope.merge!(
        scope.where(
          lead_provider_delivery_partnership: { active_lead_providers: { lead_provider: } }
        )
      )
    end

    def where_registration_period(registration_period)
      return if registration_period == :ignore

      scope.merge!(
        scope.where(
          lead_provider_delivery_partnership: { active_lead_providers: { registration_period: } }
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

    def scope
      @scope ||= SchoolPartnership
        .eager_load(
          lead_provider_delivery_partnership: [
            :delivery_partner,
            { active_lead_provider: %i[lead_provider registration_period] }
          ]
        )
    end
  end
end
