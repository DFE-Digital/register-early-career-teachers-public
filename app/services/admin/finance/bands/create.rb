module Admin::Finance::Bands
  class Create
    def initialize(author:, active_lead_provider:, capacity:)
      @author = author
      @band = active_lead_provider.bands.new(capacity:)
    end

    def create!
      ActiveRecord::Base.transaction do
        band.save!

        Events::Record.record_active_lead_provider_band_added_event!(author:, band:)
      end

      band
    end

  private

    def record_event!
    end
  end
end
