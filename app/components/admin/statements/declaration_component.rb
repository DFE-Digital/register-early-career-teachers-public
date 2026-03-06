module Admin
  module Statements
    class DeclarationComponent < ApplicationComponent
      attr_accessor :statement

      COLUMNS = [
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
        COLUMNS.map do |type|
          values = pivot_table[type]
          [type, *values.map(&:to_s)]
        end
      end

    private

      def calculators
        PaymentCalculator::Resolver.new(statement:, contract:).calculators.reverse
      end

      def ecf_contract?
        statement.contract.ecf?
      end

      def pivot_table
        matrix = Hash.new { |h, k| h[k] = Array.new(calculators.size, 0) }

        calculators.each_with_index do |calculator, index|
          calculator.outputs.declaration_type_outputs.each do |dto|
            type = payment_type(dto)
            matrix[type][index] += payments_count(dto)
          end
          matrix["Clawed back"][index] = refunded(calculator)
          matrix["Voided"][index] = voided(calculator)
        end

        matrix
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
