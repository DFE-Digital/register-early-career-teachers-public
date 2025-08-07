module Admin
  class LeadProviderPartnershipsTableComponent < ViewComponent::Base
    attr_reader :lead_provider_partnerships, :delivery_partner, :page, :q

    def initialize(lead_provider_partnerships:, delivery_partner:, page: nil, q: nil)
      @lead_provider_partnerships = lead_provider_partnerships
      @delivery_partner = delivery_partner
      @page = page
      @q = q
    end

    def render?
      lead_provider_partnerships.any?
    end

  private

    def grouped_partnerships
      @grouped_partnerships ||= lead_provider_partnerships.group_by(&:contract_period)
    end

    def change_link_path(contract_period)
      helpers.new_admin_delivery_partner_delivery_partnership_path(
        delivery_partner,
        contract_period.year,
        page:,
        q:
      )
    end

    def lead_provider_names(partnerships)
      partnerships.map(&:lead_provider).map(&:name).join(", ")
    end
  end
end
