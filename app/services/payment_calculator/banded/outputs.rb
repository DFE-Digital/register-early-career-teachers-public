module PaymentCalculator
  class Banded::Outputs
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :declarations
    attribute :previous_declarations
    attribute :banded_fee_structure

    def declaration_type_outputs
      @declaration_type_outputs ||= band_allocations.map { |band_allocation| Banded::DeclarationTypeOutput.new(band_allocation:) }
    end

    def total_billable_amount
      @total_billable_amount ||= declaration_type_outputs.sum(&:total_billable_amount)
    end

    def total_refundable_amount
      @total_refundable_amount ||= declaration_type_outputs.sum(&:total_refundable_amount)
    end

    def total_net_amount
      @total_net_amount ||= declaration_type_outputs.sum(&:total_net_amount)
    end

  private

    def band_allocator
      Banded::BandAllocator.new(bands:, previous_declarations:, declarations:)
    end

    def band_allocations
      @band_allocations ||= band_allocator.band_allocations.values.flatten
    end

    delegate :bands, to: :banded_fee_structure, private: true
  end
end
