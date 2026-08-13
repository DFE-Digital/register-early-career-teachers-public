module SchoolPartnerships
  class FindReusablePartnership
    include ContractPeriodYearConcern

    attr_reader :school, :lead_provider, :contract_period

    def initialize(school:, lead_provider:, contract_period:)
      @school = school
      @lead_provider = lead_provider
      @contract_period = contract_period
    end

    # Returns a single SchoolPartnership (the best match) or nil
    def call
      return nil unless school && lead_provider && contract_period
      return nil unless framework_agreement

      current_year_partnership || most_recent_compatible_partnership
    end

  private

    def contract_period_year
      @contract_period_year ||= to_year(contract_period)
    end

    def framework_agreement
      @framework_agreement ||=
        FrameworkAgreement
          .for_lead_provider(lead_provider.id)
          .for_contract_period_year(contract_period_year)
          .first
    end

    def base_scope
      @base_scope ||=
        SchoolPartnerships::Search
          .new(school:, lead_provider:)
          .school_partnerships
          .joins(lead_provider_delivery_partnership: :framework_agreement)
          .where(
            lead_provider_delivery_partnership: {
              delivery_partner_id: delivery_partner_ids_for_framework_agreement
            }
          )
          .unscope(:order)
    end

    def delivery_partner_ids_for_framework_agreement
      framework_agreement
        .lead_provider_delivery_partnerships
        .select(:delivery_partner_id)
    end

    def current_year_partnership
      base_scope
        .where(active_lead_providers: { contract_period_year: })
        .order(created_at: :desc, id: :desc)
        .first
    end

    def most_recent_compatible_partnership
      base_scope
        .reorder(
          "active_lead_providers.contract_period_year DESC",
          created_at: :desc,
          id: :desc
        )
        .first
    end
  end
end
