module DeliveryPartners
  class AddLeadProviderPairings
    attr_reader :delivery_partner, :contract_period, :framework_agreement_ids, :author

    def initialize(delivery_partner:, contract_period:, framework_agreement_ids:, author:)
      @delivery_partner = delivery_partner
      @contract_period = contract_period
      @framework_agreement_ids = framework_agreement_ids
      @author = author
    end

    def add!
      ActiveRecord::Base.transaction do
        ids_to_add = framework_agreement_ids_to_add
        add_partnerships(ids_to_add)
        true
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Failed to add lead provider pairings: #{e.message}"
      false
    end

  private

    def current_partnerships
      @current_partnerships ||= delivery_partner
        .lead_provider_delivery_partnerships
        .for_contract_period(contract_period)
    end

    def current_framework_agreement_ids
      @current_framework_agreement_ids ||= current_partnerships.map(&:framework_agreement_id)
    end

    def framework_agreement_ids_to_add
      framework_agreement_ids - current_framework_agreement_ids
    end

    def add_partnerships(ids_to_add)
      FrameworkAgreement
        .includes(:lead_provider, :contract_period)
        .where(id: ids_to_add)
        .find_each do |framework_agreement|
          LeadProviderDeliveryPartnerships::Create.new(
            author:,
            framework_agreement:,
            params: { delivery_partner_id: delivery_partner.id }
          ).call
        end
    end
  end
end
