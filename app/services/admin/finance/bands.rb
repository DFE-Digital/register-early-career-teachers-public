module Admin::Finance
  class Bands
    attr_reader :active_lead_provider

    def initialize(active_lead_provider:)
      @active_lead_provider = active_lead_provider
    end

    def label_for(band:)
      "Band #{band.letter}"
    end

    def capacity_description_for(band:)
      "#{band.min_declarations} - #{band.max_declarations}"
    end

    def bands_can_be_added?
      no_contracts_and_contract_period_not_started?
    end
    alias_method :bands_can_be_added_and_removed?, :bands_can_be_added?

    def editable?(band:)
      last?(band:)
    end

    def bands_can_be_deleted?
      no_contracts_and_contract_period_not_started?
    end

    def deletable_band?(band:)
      last?(band:) && bands_can_be_deleted?
    end

    def last?(band:)
      active_lead_provider.bands.last == band
    end

    def delete!(band:)
      if deletable_band?(band:)
        band.destroy!
      else
        raise "Band cannot be deleted"
      end
    end

  private

    def no_contracts_and_contract_period_not_started?
      contract_period_started_on.future? && contracts.none?
    end

    def contract_period_started_on
      active_lead_provider.contract_period.started_on
    end

    def contracts
      active_lead_provider.contracts
    end
  end
end
