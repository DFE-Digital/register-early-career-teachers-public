module PaymentCalculator
  class Banded::BandAllocator
    # Allocates declaration counts into tiered pricing bands for a single
    # contract period and lead provider, broken down by declaration type.
    #
    # Billable declarations are added to bands from lowest to highest (A → D),
    # each band accepting up to its capacity (max - min + 1 declarations).
    # Refundable (clawback) declarations are removed from bands in reverse (D → A).
    #
    # The allocation runs across all statements cumulatively:
    #
    #   1. Previous statements' billable declarations are added first (A → D)
    #   2. Previous statements' refundable declarations are removed (D → A)
    #   3. Current statement's billable declarations are added to remaining capacity (A → D)
    #   4. Current statement's refundable declarations are removed (D → A)
    #
    # The result is an overall band count per declaration type that reflects
    # every statement up to and including the current one.
    #
    # Returns an Array of BandAllocation objects.
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :bands                  # ordered bands by min/max count
    attribute :previous_declarations  # previous statements declarations
    attribute :declarations           # current statements declarations

    def band_allocations_by_declaration_type
      @band_allocations_by_declaration_type ||= build_band_allocations_by_declaration_type
    end

  private

    def declaration_types
      (previous_declarations.pluck(:declaration_type) + declarations.pluck(:declaration_type)).uniq
    end

    def build_band_allocations_by_declaration_type
      # Initialize band allocations for every (declaration_type, band) pair
      declaration_types.flat_map do |declaration_type|
        allocations = bands.map do |band|
          Banded::BandAllocation.new(band:, declaration_type:)
        end

        # Run allocate for each declaration type
        allocate_for_declaration_type(declaration_type, allocations)

        allocations
      end
    end

    def allocate_for_declaration_type(declaration_type, allocations)
      # Step 1: Add previous billable declarations A-D
      count = previous_billable_count(declaration_type)
      add_previous_billable_to_bands(allocations, count)

      # Step 2: Remove previous refundable declarations D-A
      count = previous_refundable_count(declaration_type)
      remove_previous_refundable_from_bands(allocations, count)

      # Step 3: Add current billable declarations A-D
      count = current_billable_count(declaration_type)
      add_billable_to_bands(allocations, count)

      # Step 4: Remove current refundable declarations D-A
      count = current_refundable_count(declaration_type)
      remove_refundable_from_bands(allocations, count)
    end

    def add_previous_billable_to_bands(allocations, count)
      remaining = count
      allocations.each do |allocation|
        break if remaining.zero?

        remaining -= allocation.add_previous_billable(remaining)
      end
    end

    def remove_previous_refundable_from_bands(allocations, count)
      remaining = count
      allocations.reverse_each do |allocation|
        break if remaining.zero?

        remaining -= allocation.remove_previous_refundable(remaining)
      end
    end

    def add_billable_to_bands(allocations, count)
      remaining = count
      allocations.each do |allocation|
        break if remaining.zero?

        remaining -= allocation.add_billable(remaining)
      end
    end

    def remove_refundable_from_bands(allocations, count)
      remaining = count
      allocations.reverse_each do |allocation|
        break if remaining.zero?

        remaining -= allocation.remove_refundable(remaining)
      end
    end

    def previous_billable_count(declaration_type)
      previous_declarations.billable.where(declaration_type:).count
    end

    def previous_refundable_count(declaration_type)
      previous_declarations.refundable.where(declaration_type:).count
    end

    def current_billable_count(declaration_type)
      declarations.billable.where(declaration_type:).count
    end

    def current_refundable_count(declaration_type)
      declarations.refundable.where(declaration_type:).count
    end
  end
end
