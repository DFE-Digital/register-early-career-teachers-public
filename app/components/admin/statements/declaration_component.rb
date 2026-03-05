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
        d = mapped_declarations || []
        d << ["Voided", voided.to_s]
        d
      end

    private

      def calculators
        PaymentCalculator::Resolver.new(statement:, contract:).calculators
      end

      def declaration_type_outputs
        @declaration_type_outputs ||= calculators.first.outputs.declaration_type_outputs
      end

      def payments_count(declaration_type_output)
        declaration_type_output.billable_count - declaration_type_output.refundable_count
      end

      def payment_type(declaration_type_output)
        declaration_type_output.declaration_type.humanize
      end

      def mapped_declarations
        @mapped_declarations ||= declaration_type_outputs.map { |dto| [payment_type(dto), payments_count(dto).to_s] }
      end

      def voided
        @voided ||= statement.payment_declarations.where(payment_status: "voided").count
      end
    end
  end
end
