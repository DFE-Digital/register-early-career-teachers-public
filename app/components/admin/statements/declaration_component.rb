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
        if ecf_contract?
          %w[Total]
        else
          %w[ECTs Mentors]
        end
      end

      def columns
        @columns ||= build_columns
      end

    private

      def ecf_contract?
        contract.ecf_contract_type?
      end

      def calculators
        PaymentCalculator::Resolver.new(statement:, contract:).calculators
      end

      def ordered_calculators
        case contract.contract_type
        when "ecf"
          raise ArgumentError, "Expected one banded calculator for ECF contract type" unless calculators.one? && banded_calculator

          [banded_calculator]
        when "ittecf_ectp"
          raise ArgumentError, "Expected banded and flat rate calculator for ITTECF ECTP contract type" unless flat_rate_calculator && banded_calculator

          [banded_calculator, flat_rate_calculator]
        else
          raise ArgumentError
        end
      end

      def banded_calculator
        calculators.find { |c| c.is_a? PaymentCalculator::Banded }
      end

      def flat_rate_calculator
        calculators.find { |c| c.is_a? PaymentCalculator::FlatRate }
      end

      def initialise_columns
        columns = {}
        ORDERED_ROW_NAMES.each do |declaration_type|
          columns[declaration_type] = Array.new(ordered_calculators.size, 0)
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
        ordered_calculators.each_with_index do |calculator, index|
          calculator.outputs.declaration_type_outputs.each do |dto|
            type = payment_type(dto)
            columns[type][index] += payments_count(dto)
          end
        end
      end

      def voided_and_refunded_declarations(columns)
        ordered_calculators.each_with_index do |calculator, index|
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
