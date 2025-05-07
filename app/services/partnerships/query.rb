module Partnerships
  class Query
    include API::Concerns::FilterIgnorable

    attr_reader :scope

    def initialize(lead_provider: :ignore)
      @scope = all_partnerships

      where_lead_provider_is(lead_provider)
    end

    def partnerships
      scope.order(created_at: :asc)
    end

    def partnership(id: nil)
      scope.where(id:)
    end

  private

    def where_lead_provider_is(lead_provider)
      return if ignore?(filter: lead_provider)

      scope.merge!(SchoolPartnership.for_lead_provider(lead_provider.id))
    end

    def all_partnerships
      SchoolPartnership
        .includes(:school,
                  :delivery_partner,
                  :registration_period)
    end
  end
end
