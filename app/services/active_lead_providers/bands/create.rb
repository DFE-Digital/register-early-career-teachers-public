module ActiveLeadProviders::Bands
  class Create
    attr_reader :author, :band

    def initialize(author:, active_lead_provider:, capacity:)
      @author = author
      @band = ActiveLeadProvider::Band.new(active_lead_provider:, capacity:)
    end

    def create!
      ActiveRecord::Base.transaction do
        band.save!

        Events::Record.record_active_lead_provider_band_added_event!(author:, band:)
      end

      band
    end
  end
end
