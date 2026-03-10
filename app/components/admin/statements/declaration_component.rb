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

      def headers
        if contract.ecf_contract_type?
          %w[Total]
        else
          %w[ECTs Mentors]
        end
      end

      def columns
        @columns ||= build_columns
      end

    private

      def calculators
        PaymentCalculator::Resolver.new(statement:, contract:).calculators.reverse
      end

      def initialise_columns
        columns = {}
        ORDERED_ROW_NAMES.each do |declaration_type|
          columns[declaration_type] = Array.new(calculators.size, 0)
        end
        columns
      end

      def build_columns
        columns = initialise_columns
        sum_declarations(columns)
        voided_and_refunded_declarations(columns)

        columns
      end

      def sum_declarations(columns)
        calculators.each_with_index do |calculator, index|
          calculator.outputs.declaration_type_outputs.each do |dto|
            type = payment_type(dto)
            columns[type][index] += payments_count(dto)
          end
        end
      end

      def voided_and_refunded_declarations(columns)
        calculators.each_with_index do |calculator, index|
          columns["Clawed back"][index] = refunded(calculator)
          columns["Voided"][index] = voided(calculator)
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
