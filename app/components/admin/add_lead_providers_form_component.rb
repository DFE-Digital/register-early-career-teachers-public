module Admin
  class AddLeadProvidersFormComponent < ApplicationComponent
    attr_reader :delivery_partner, :current_partnerships, :available_lead_providers, :year, :page, :q

    def initialize(delivery_partner:, current_partnerships:, available_lead_providers:, year:, page: nil, q: nil)
      @delivery_partner = delivery_partner
      @current_partnerships = current_partnerships
      @available_lead_providers = available_lead_providers
      @year = year
      @page = page
      @q = q
    end

    private

    def form_url
      helpers.admin_delivery_partner_delivery_partnership_path(delivery_partner, year)
    end

    def back_link_path
      params = {}
      params[:page] = page if page.present?
      params[:q] = q if q.present?
      helpers.admin_delivery_partner_path(delivery_partner, params)
    end

    def current_partnership_names
      current_partnerships.map { |partnership| partnership.lead_provider.name }
    end

    def legend_text
      "Add new lead providers"
    end

    def hint_text
      "Select additional lead providers that should work with #{delivery_partner.name} in #{year}"
    end
  end
end
