module FrameworkAgreements::Bands
  class Update
    attr_reader :band, :author, :capacity

    def initialize(author:, band:, capacity:)
      @author = author
      @band = band
      @capacity = capacity
    end

    def update!
      band.assign_attributes(capacity:)
      modifications = band.changes

      ActiveRecord::Base.transaction do
        band.save!
        Events::Record.record_framework_agreement_band_updated_event!(author:, band:, modifications:)
      end

      band
    end
  end
end
