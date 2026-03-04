module Admin
  module Statements
    class DeclarationComponent < ApplicationComponent
      attr_accessor :statement
      delegate :contract, to: :statement

      def initialize(statement:)
        @statement = statement
      end

      private

      def calculators
        PaymentCalculator::Resolver.new(statement:, contract:).calculators
      end

      def declaration_type_outputs
        @declaration_type_outputs ||= calculators.first.outputs.declaration_type_outputs
      end

      def payment_type(declaration_type_output)
        declaration_type_output.declaration_type.humanize
      end
    end
  end
end


