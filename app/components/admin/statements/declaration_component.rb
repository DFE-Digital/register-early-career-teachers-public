module Admin
  module Statements
    class DeclarationComponent < ApplicationComponent
      attr_accessor :statement

      delegate :contract, to: :statement

      def initialize(statement:)
        @statement = statement
      end

      def head
        ["", "Total"]
      end

      def rows
        rows = mapped_declarations || []
        rows << ["Voided", voided]

        rows
        .group_by(&:first)
        .map { |type, group| [type, group.sum(&:last).to_s] }
      end

    private

      def calculators
        PaymentCalculator::Resolver.new(statement:, contract:).calculators
      end

      def mapped_declarations
        mappings = []
        calculators.each do |calculator|
          declaration_type_output = calculator.outputs.declaration_type_outputs
          mappings.concat(mapped(declaration_type_output))
        end
        mappings
      end

      def mapped(declaration_type_outputs)
        declaration_type_outputs.map { |dto| [payment_type(dto), payments_count(dto)] }
      end

      def payments_count(declaration_type_output)
        declaration_type_output.billable_count - declaration_type_output.refundable_count
      end

      def payment_type(declaration_type_output)
        declaration_type_output.declaration_type.humanize
      end

      def voided
        @voided ||= statement.payment_declarations.where(payment_status: "voided").count
      end
    end
  end
end
