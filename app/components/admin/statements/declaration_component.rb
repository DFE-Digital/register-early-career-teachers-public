module Admin
  module Statements
    class DeclarationComponent < ApplicationComponent
      attr_accessor :statement

      ORDERED_ROW_NAMES = [
        "Started",
        "Retained",
        "Completed",
        "Extended",
        "Clawed back",
        "Voided"
      ].freeze

      delegate :contract, to: :statement

      def initialize(statement:)
        @statement = statement
      end

      def head
        if ecf_contract?
          ["", "Total"]
        else
          ["", "ECTs", "Mentors"]
        end
      end

      def rows
        ORDERED_ROW_NAMES.map do |declaration_type|
          format_row(declaration_type)
        end
      end

    private

      def calculators
        PaymentCalculator::Resolver.new(statement:, contract:).calculators.reverse
      end

      def format_row(declaration_type)
        values = table[declaration_type]

        [declaration_type, *values.map(&:to_s)]
      end

      def table
        @table ||= build_table
      end

      def ecf_contract?
        contract.contract_type == "ecf"
      end

      def initialise_table
        table = {}
        ORDERED_ROW_NAMES.each do |declaration_type|
          table[declaration_type] = Array.new(calculators.size, 0)
        end
        table
      end

      def build_table
        table = initialise_table
        sum_declarations(table)
        voided_and_refunded_declarations(table)

        table
      end

      def sum_declarations(table)
        calculators.each_with_index do |calculator, index|
          calculator.outputs.declaration_type_outputs.each do |dto|
            type = payment_type(dto)
            table[type][index] += payments_count(dto)
          end
        end
      end

      def voided_and_refunded_declarations(table)
        calculators.each_with_index do |calculator, index|
          table["Clawed back"][index] = refunded(calculator)
          table["Voided"][index] = voided(calculator)
        end
      end

      def refunded(calculator)
        calculator.outputs.total_refundable_amount.to_i
      end

      def voided(calculator)
        calculator.voided_declarations_count.to_i
      end

      def payments_count(declaration_type_output)
        declaration_type_output.billable_count - declaration_type_output.refundable_count
      end

      def payment_type(declaration_type_output)
        declaration_type_output.declaration_type.split("-").first.humanize
      end
    end
  end
end
