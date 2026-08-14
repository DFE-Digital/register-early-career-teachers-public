module Admin::Finance::FrameworkAgreements
  class LeadProviderDeliveryPartnershipsController < Admin::Finance::BaseController
    layout "full"

    before_action :set_framework_agreement
    before_action :set_lead_provider_delivery_partnership, only: %i[delete destroy]
    before_action :redirect_unless_editable, only: %i[new create delete destroy]

    def index
      contract_period = @framework_agreement.contract_period

      @breadcrumbs = {
        "Finance" => admin_finance_path,
        "Contract periods" => admin_contract_periods_path,
        @framework_agreement.contract_period_year.to_s => admin_contract_period_path(contract_period),
        @framework_agreement.lead_provider_name => admin_contract_period_framework_agreements_path(contract_period),
      }
      @pagy, @lead_provider_delivery_partnerships = pagy(
        @framework_agreement.lead_provider_delivery_partnerships.includes(:delivery_partner).order("delivery_partners.name")
      )
    end

    def new
      @lead_provider_delivery_partnership = LeadProviderDeliveryPartnership.new
      @available_delivery_partners = available_delivery_partners
    end

    def create
      ::LeadProviderDeliveryPartnerships::Create.new(
        author: current_user,
        framework_agreement: @framework_agreement,
        params: lead_provider_delivery_partnership_params
      ).call

      redirect_to index_path, notice: "Delivery partner added"
    rescue ActiveRecord::RecordInvalid => e
      @lead_provider_delivery_partnership = e.record
      @available_delivery_partners = available_delivery_partners
      render :new, status: :unprocessable_content
    end

    def delete
      # This is our project specific pattern, so we need a comment to keep sonarcube happy.
    end

    def destroy
      ::LeadProviderDeliveryPartnerships::Destroy.new(
        author: current_user,
        lead_provider_delivery_partnership: @lead_provider_delivery_partnership
      ).call

      redirect_to index_path, notice: "Delivery partner removed"
    rescue ::LeadProviderDeliveryPartnerships::Destroy::DeletionError => e
      redirect_to index_path, flash: { error: e.message }
    end

  private

    def set_framework_agreement
      @framework_agreement = FrameworkAgreement
        .includes(:contract_period, :lead_provider)
        .find(params[:framework_agreement_id])
    end

    def set_lead_provider_delivery_partnership
      @lead_provider_delivery_partnership = @framework_agreement.lead_provider_delivery_partnerships.find(params[:id])
    end

    def redirect_unless_editable
      unless @framework_agreement.editable?
        redirect_to index_path,
                    flash: {
                      error: "Delivery partnerships cannot be changed once the contract period has started"
                    }
      end
    end

    def lead_provider_delivery_partnership_params
      params.expect(lead_provider_delivery_partnership: [:delivery_partner_id])
    end

    def available_delivery_partners
      DeliveryPartner.where.not(id: @framework_agreement.delivery_partner_ids).order(:name)
    end

    def index_path
      admin_contract_period_framework_agreement_lead_provider_delivery_partnerships_path(
        @framework_agreement.contract_period, @framework_agreement
      )
    end
  end
end
