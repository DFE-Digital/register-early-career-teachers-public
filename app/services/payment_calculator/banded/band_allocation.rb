module PaymentCalculator
  class Banded::BandAllocation
    attr_reader :band, :declaration_type,
                :previous_billable_count, :previous_refundable_count,
                :billable_count, :refundable_count

    def initialize(band:, declaration_type:)
      @band = band
      @declaration_type = declaration_type
      @previous_billable_count = 0
      @previous_refundable_count = 0
      @billable_count = 0
      @refundable_count = 0
    end

    delegate :capacity, to: :band

    def net_billable_count
      (previous_billable_count + billable_count) - (previous_refundable_count + refundable_count)
    end

    def available_capacity
      [capacity - net_billable_count, 0].max
    end

    def add_previous_billable(count)
      amount = [count, available_capacity].min
      @previous_billable_count += amount
      amount
    end

    def remove_previous_refundable(count)
      amount = [count, net_billable_count].min
      @previous_refundable_count += amount
      amount
    end

    def add_billable(count)
      amount = [count, available_capacity].min
      @billable_count += amount
      amount
    end

    def remove_refundable(count)
      amount = [count, net_billable_count].min
      @refundable_count += amount
      amount
    end
  end
end
