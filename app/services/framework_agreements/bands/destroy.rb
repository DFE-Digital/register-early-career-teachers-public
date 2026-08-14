module FrameworkAgreements::Bands
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

      framework_agreement = band.framework_agreement
      band_letter = band.letter

      ActiveRecord::Base.transaction do
        band.destroy!

        Events::Record.record_framework_agreement_band_deleted_event!(
          author:,
          framework_agreement:,
          band_letter:
        )
      end

      true
    end
  end
end
