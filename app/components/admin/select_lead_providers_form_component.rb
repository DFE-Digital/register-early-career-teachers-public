module Admin
  class SelectLeadProvidersFormComponent < ViewComponent::Base
    attr_reader :delivery_partner, :contract_period, :current_partnerships, :year, :page, :q

    def initialize(delivery_partner:, contract_period:, current_partnerships:, year:, page: nil, q: nil)
      @delivery_partner = delivery_partner
      @contract_period = contract_period
      @current_partnerships = current_partnerships
      @year = year
      @page = page
      @q = q
    end

  private

    def form_url
      helpers.admin_delivery_partner_path(delivery_partner)
    end

    def back_link_path
      params = {}
      params[:page] = page if page.present?
      params[:q] = q if q.present?
      helpers.admin_delivery_partner_path(delivery_partner, params)
    end

    def all_lead_providers_for_period
      @all_lead_providers_for_period ||= ActiveLeadProvider
        .joins(:lead_provider)
        .where(contract_period:)
        .includes(:lead_provider)
        .order("lead_providers.name")
    end

    def currently_selected_ids
      @currently_selected_ids ||= current_partnerships.map(&:active_lead_provider_id).map(&:to_s)
    end

    def legend_text
      "Select lead providers"
    end

    def hint_text
      "Select lead providers that should work with #{delivery_partner.name} in #{year}"
    end

    def selected?(active_lead_provider)
      currently_selected_ids.include?(active_lead_provider.id.to_s)
    end
  end
end
