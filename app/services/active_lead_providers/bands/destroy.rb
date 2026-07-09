module ActiveLeadProviders::Bands
  class Destroy
    class DeletionError < StandardError; end

    attr_reader :band, :author

    def initialize(author:, band:)
      @author = author
      @band = band
    end

    def destroy!
      raise DeletionError, "Cannot delete a band that is not the last for a period" unless band.last?
      raise DeletionError, "Cannot delete a band once the contract period has started or if there are contracts for the period" unless band.deletable?

      active_lead_provider = band.active_lead_provider
      band_letter = band.letter

      ActiveRecord::Base.transaction do
        band.destroy!

        Events::Record.record_active_lead_provider_band_deleted_event!(
          author:,
          active_lead_provider:,
          band_letter:
        )
      end

      true
    end
  end
end
