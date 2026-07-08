module Admin::Finance::Bands
  class Update
    attr_reader :band, :author, :capacity

    def initialize(author:, band:, capacity:)
      @author = author
      @band = band
      @capacity = capacity
    end

    def call
      band.assign_attributes(capacity:)
      band.changes

      ActiveRecord::Base.transaction do
        band.save!
        # TODO:
        # Events::Record.record_active_lead_provider_band_updated_event!(author:, band:, modifications:)
      end

      band
    end
  end
end
