module DeliveryPartners
  class UpdateLeadProviderPairings
    attr_reader :delivery_partner, :contract_period, :framework_agreement_ids, :author

    def initialize(delivery_partner:, contract_period:, framework_agreement_ids:, author:)
      @delivery_partner = delivery_partner
      @contract_period = contract_period
      @framework_agreement_ids = framework_agreement_ids
      @author = author
    end

    def update!
      ActiveRecord::Base.transaction do
        ids_to_add = framework_agreement_ids_to_add
        ids_to_remove = framework_agreement_ids_to_remove

        remove_partnerships(ids_to_remove)
        add_partnerships(ids_to_add)
        true
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Failed to update lead provider pairings: #{e.message}"
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

    def framework_agreement_ids_to_remove
      current_framework_agreement_ids - framework_agreement_ids
    end

    def add_partnerships(ids_to_add)
      ids_to_add.each do |framework_agreement_id|
        framework_agreement = FrameworkAgreement.find(framework_agreement_id)
        LeadProviderDeliveryPartnerships::Create.new(
          author:,
          framework_agreement:,
          params: { delivery_partner_id: delivery_partner.id }
        ).call
      end
    end

    def remove_partnerships(ids_to_remove)
      ids_to_remove.each do |framework_agreement_id|
        partnership = current_partnerships.find_by(framework_agreement_id:)
        next unless partnership

        framework_agreement = partnership.framework_agreement

        record_partnership_removed_event(framework_agreement, partnership)
        partnership.destroy!
      end
    end

    def record_partnership_removed_event(framework_agreement, removed_partnership)
      Events::Record.record_lead_provider_delivery_partnership_removed_event!(
        delivery_partner:,
        lead_provider: framework_agreement.lead_provider,
        contract_period:,
        author:,
        lead_provider_delivery_partnership: removed_partnership
      )
    end
  end
end
