module Admin
  module DeliveryPartners
    class AddLeadProviders
      attr_reader :delivery_partner_id, :year, :lead_provider_ids, :author

      def initialize(delivery_partner_id:, year:, lead_provider_ids:, author:)
        @delivery_partner_id = delivery_partner_id
        @year = year
        @lead_provider_ids = lead_provider_ids
        @author = author
      end

      def call
        validate_delivery_partner
        validate_contract_period
        validate_lead_provider_ids
        update_lead_provider_pairings
      end

    private

      def validate_delivery_partner
        @delivery_partner = DeliveryPartner.find(delivery_partner_id)
      rescue ActiveRecord::RecordNotFound
        raise ValidationError, "Delivery partner not found"
      end

      def validate_contract_period
        @contract_period = ContractPeriod.find_by(year:)
        raise ValidationError, "Contract period for year #{year} not found" if @contract_period.blank?
      end

      def validate_lead_provider_ids
        # Filter out empty values that might be sent by form helpers
        @active_lead_provider_ids = (lead_provider_ids || [])
          .reject(&:blank?)
          .map(&:to_i)

        raise NoLeadProvidersSelectedError, "Select at least one lead provider" if @active_lead_provider_ids.empty?
      end

      def update_lead_provider_pairings
        result = ::DeliveryPartners::UpdateLeadProviderPairings.new(
          delivery_partner: @delivery_partner,
          contract_period: @contract_period,
          active_lead_provider_ids: @active_lead_provider_ids,
          author:
        ).update!

        raise ValidationError, "Unable to update lead provider partners" unless result
      end

      class ValidationError < StandardError; end
      class NoLeadProvidersSelectedError < StandardError; end
    end
  end
end
