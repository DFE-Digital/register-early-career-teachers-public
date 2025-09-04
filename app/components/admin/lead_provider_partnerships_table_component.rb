module Admin
  class LeadProviderPartnershipsTableComponent < ApplicationComponent
    attr_reader :contract_period_partnerships, :delivery_partner, :page, :q

    def initialize(contract_period_partnerships:, delivery_partner:, page: nil, q: nil)
      @contract_period_partnerships = contract_period_partnerships
      @delivery_partner = delivery_partner
      @page = page
      @q = q
    end

    def render?
      contract_period_partnerships.any?
    end

  private

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
