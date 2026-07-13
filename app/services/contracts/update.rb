module Contracts
  class Update
    attr_reader :author, :contract, :params

    def initialize(author:, contract:, params:)
      @author = author
      @contract = contract
      @params = params
    end

    def call
      ActiveRecord::Base.transaction do
        contract.assign_attributes(params)
        modifications = collect_modifications
        contract.save!
        Events::Record.record_contract_updated_event!(author:, contract:, modifications:)
        contract
      end
    end

  private

    def collect_modifications
      modifications = contract.changes.dup
      add_fee_structure_modifications(modifications, "flat_rate", contract.flat_rate_fee_structure)
      add_fee_structure_modifications(modifications, "banded", contract.banded_fee_structure)
      add_band_term_modifications(modifications)
      modifications
    end

    def add_fee_structure_modifications(modifications, prefix, fee_structure)
      return unless fee_structure&.changed?

      fee_structure.changes.each do |attribute, values|
        next if attribute == "updated_at"

        modifications["#{prefix}_#{attribute}"] = values
      end
    end

    def add_band_term_modifications(modifications)
      return unless contract.banded_fee_structure

      contract.banded_fee_structure.band_terms.each do |band_term|
        next unless band_term.changed? || band_term.marked_for_destruction?

        if band_term.marked_for_destruction?
          modifications["band_#{band_term.letter}_removed"] = [true, false]
        else
          band_term.changes.each do |attribute, values|
            next if attribute == "updated_at"

            modifications["band_#{band_term.letter}_#{attribute}"] = values
          end
        end
      end
    end
  end
end
