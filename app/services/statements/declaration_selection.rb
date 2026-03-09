# Payment calculators allocate counts, this service selects specific records in deterministic order for CSV export.
#
# TODO: This service duplicates declaration selection logic from `PaymentCalculator`.
# Extract a shared source of truth so the finance statement and CSV export cannot drift.

module Statements
  class DeclarationSelection
    class UnsupportedCalculatorError < StandardError; end

    ORDER_BY = { declaration_date: :asc, created_at: :asc, id: :asc }.freeze

    attr_reader :statement

    def initialize(statement:)
      @statement = statement
    end

    def selected_declaration_ids
      @selected_declaration_ids ||= calculators
        .flat_map { |calculator| selected_ids_for(calculator) }
        .uniq
    end

  private

    def calculators
      @calculators ||= PaymentCalculator::Resolver.new(statement:).calculators
    end

    def selected_ids_for(calculator)
      case calculator
      when PaymentCalculator::Banded
        selected_ids_for_banded(calculator)
      when PaymentCalculator::FlatRate
        selected_ids_for_flat_rate(calculator)
      else
        raise UnsupportedCalculatorError, "Unsupported calculator: #{calculator.class.name}"
      end
    end

    def selected_ids_for_flat_rate(calculator)
      filtered_declarations = calculator.declaration_selector.call(current_billable_declarations.or(current_refundable_declarations))
      ordered(filtered_declarations).pluck(:id)
    end

    def selected_ids_for_banded(calculator)
      filtered_current_billable = ordered(calculator.declaration_selector.call(current_billable_declarations))
      filtered_current_refundable = ordered(calculator.declaration_selector.call(current_refundable_declarations))
      filtered_previous_billable = calculator.declaration_selector.call(previous_billable_declarations)
      filtered_previous_refundable = calculator.declaration_selector.call(previous_refundable_declarations)

      allocations = PaymentCalculator::Banded::BandAllocator.new(
        bands: calculator.banded_fee_structure.bands,
        billable_declarations: filtered_current_billable,
        refundable_declarations: filtered_current_refundable,
        previous_billable_declarations: filtered_previous_billable,
        previous_refundable_declarations: filtered_previous_refundable
      ).band_allocations_by_declaration_type

      billable_selection_limits = allocations.group_by(&:declaration_type).transform_values { |rows| rows.sum(&:billable_count) }
      refundable_selection_limits = allocations.group_by(&:declaration_type).transform_values { |rows| rows.sum(&:refundable_count) }

      select_ids_by_type(filtered_current_billable, billable_selection_limits) +
        select_ids_by_type(filtered_current_refundable, refundable_selection_limits)
    end

    def select_ids_by_type(declarations, selection_limits_by_declaration_type)
      selection_limits_by_declaration_type.flat_map do |declaration_type, selection_limit|
        next [] if selection_limit.zero?

        declarations.where(declaration_type:).reorder(ORDER_BY).limit(selection_limit).pluck(:id)
      end
    end

    def current_billable_declarations
      @current_billable_declarations ||= Declaration.where(payment_statement: statement).billable
    end

    def current_refundable_declarations
      @current_refundable_declarations ||= Declaration.where(clawback_statement: statement).refundable
    end

    def previous_billable_declarations
      @previous_billable_declarations ||= Declaration.where(payment_statement: previous_statements).billable
    end

    def previous_refundable_declarations
      @previous_refundable_declarations ||= Declaration.where(clawback_statement: previous_statements).refundable
    end

    def previous_statements
      @previous_statements ||= Statement.joins(:contract)
        .where(contracts: { active_lead_provider_id: statement.active_lead_provider.id })
        .where(payment_date: ...statement.payment_date)
    end

    def ordered(declarations)
      declarations.order(ORDER_BY)
    end
  end
end
