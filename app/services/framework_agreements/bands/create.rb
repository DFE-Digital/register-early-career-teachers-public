module FrameworkAgreements::Bands
  class Create
    attr_reader :author, :band

    def initialize(author:, framework_agreement:, capacity:)
      @author = author
      @band = FrameworkAgreement::Band.new(framework_agreement:, capacity:)
    end

    def create!
      ActiveRecord::Base.transaction do
        band.save!

        Events::Record.record_framework_agreement_band_added_event!(author:, band:)
      end

      band
    end
  end
end
