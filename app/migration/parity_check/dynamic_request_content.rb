module ParityCheck
  class DynamicRequestContent
    include ActiveModel::Model
    include ActiveModel::Attributes

    class Error < RuntimeError; end
    class UnrecognizedIdentifierError < Error; end

    attribute :lead_provider

    def fetch(identifier)
      raise UnrecognizedIdentifierError, "Identifier not recognized: #{identifier}" unless respond_to?(identifier, true)

      @fetch ||= {}
      @fetch[identifier] ||= send(identifier)
    end

  private

    # Path ID methods

    def statement_id
      API::Statements::Query.new(lead_provider_id: lead_provider.id)
        .statements
        .distinct(false)
        .reorder("RANDOM()")
        .pick(:api_id)
    end

    def school_id
      contract_period_year = ContractPeriod.order("RANDOM()").pick(:year)
      API::Schools::Query.new(contract_period_year:)
        .schools
        .distinct(false)
        .reorder("RANDOM()")
        .pick(:api_id)
    end

    def delivery_partner_id
      API::DeliveryPartners::Query.new(lead_provider_id: lead_provider.id)
        .delivery_partners
        .distinct(false)
        .reorder("RANDOM()")
        .pick(:api_id)
    end

    def partnership_id
      ::Migration::Partnership
        .where(lead_provider_id: lead_provider.ecf_id)
        .where(challenged_at: nil, relationship: false)
        .reorder("RANDOM()")
        .pick(:id)
    end

    # Request body methods

    def partnership_create_body
      contract_period = random_contract_period
      return unless contract_period

      lead_provider_delivery_partnerships = lead_provider_delivery_partnerships(contract_period:)
      return unless lead_provider_delivery_partnerships.any?

      school = random_other_eligible_school(lead_provider_delivery_partnerships:)
      return unless school

      delivery_partner = lead_provider_delivery_partnerships.map(&:delivery_partner).uniq.sample

      {
        data: {
          type: "partnerships",
          attributes: {
            cohort: contract_period.year,
            school_id: school.api_id,
            delivery_partner_id: delivery_partner.api_id,
          },
        },
      }
    end

    def partnership_update_body
      school_partnership = random_school_partnership
      return unless school_partnership

      contract_period = school_partnership.contract_period
      lead_provider_delivery_partnership = school_partnership.lead_provider_delivery_partnership
      lead_provider_delivery_partnerships = lead_provider_delivery_partnerships(contract_period:).where.not(id: lead_provider_delivery_partnership.id)
      return unless lead_provider_delivery_partnerships.any?

      delivery_partner = lead_provider_delivery_partnerships.sample.delivery_partner

      {
        data: {
          type: "partnerships",
          attributes: {
            delivery_partner_id: delivery_partner.api_id,
          },
        },
      }
    end

    # Helpers

    def random_school_partnership
      SchoolPartnership.find_by(api_id: partnership_id)
    end

    def random_contract_period
      lead_provider
        .lead_provider_delivery_partnerships
        .joins(:contract_period)
        .where(contract_period: { enabled: true })
        .order("RANDOM()")
        .first
        &.contract_period
    end

    def lead_provider_delivery_partnerships(contract_period:)
      lead_provider
        .lead_provider_delivery_partnerships
        .joins(:active_lead_provider)
        .where(active_lead_provider: { contract_period: })
    end

    def random_other_eligible_school(lead_provider_delivery_partnerships:)
      existing_school_ids = lead_provider_delivery_partnerships
        .joins(school_partnerships: :school)
        .pluck(:school_id)
        .uniq

      School.where.not(id: existing_school_ids).eligible.not_cip_only.order("RANDOM()").first
    end
  end
end
