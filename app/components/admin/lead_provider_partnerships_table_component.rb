module Admin
  class LeadProviderPartnershipsTableComponent < ApplicationComponent
    attr_reader :partnership_data, :delivery_partner, :page, :q

    # Expects partnerhsip data in format { 2026 => ["Lead provider one name", "Lead provider two name"] }
    def initialize(partnership_data:, delivery_partner:, page: nil, q: nil)
      @partnership_data = partnership_data
      @delivery_partner = delivery_partner
      @page = page
      @q = q
    end

    def render?
      partnership_data.present?
    end

  private

    def change_link_path(year)
      helpers.new_admin_delivery_partner_delivery_partnership_path(delivery_partner, year, page:, q:)
    end

    def display_lead_provider_names(lead_provider_names)
      return "Not reported" if lead_provider_names.empty?

      lead_provider_names.join(", ")
    end
  end
end
