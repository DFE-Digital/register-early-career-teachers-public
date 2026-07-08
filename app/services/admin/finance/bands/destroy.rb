module Admin::Finance::Bands
  class Destroy
    class DeletionError < StandardError; end

    attr_reader :band, :author

    def initialize(author:, band:)
      @author = author
      @band = band
    end

    def call
      raise DeletionError, "Cannot delete a band that is not the last for a period" unless band.last?
      raise DeletionError, "Cannot delete a band once the contract period has started or if there are contracts for the period" unless band.deletable?

      active_lead_provider = band.active_lead_provider
      active_lead_provider.lead_provider
      active_lead_provider.contract_period
      band.attributes.transform_values { |value| [value, nil] }

      ActiveRecord::Base.transaction do
        band.destroy!

        # TODO: add event
        # Events::Record.record_active_lead_provider_band_deleted_event!(
        #   author:,
        #   active_lead_provider:,
        #   lead_provider:,
        #   contract_period:,
        #   modifications:,
        #   heading:
        # )
      end

      true
    end
  end
end
