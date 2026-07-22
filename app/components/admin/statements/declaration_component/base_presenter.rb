module Admin
  module Statements
    class DeclarationComponent < ApplicationComponent
      class BasePresenter < SimpleDelegator
        delegate :declaration_type_outputs, :total_refundable_count, to: :outputs, private: true

        def count_for(type)
          declaration_type_outputs
            .select { it.declaration_type.start_with?(type) }
            .sum(&:billable_count)
            .to_s
        end

        def clawbacks_count = total_refundable_count.to_s

        def voided_count = voided_declarations_count.to_s
      end
    end
  end
end
