module Admin
  module Statements
    class OutputPaymentsComponent < ApplicationComponent
      class BasePresenter < SimpleDelegator
        delegate :total_billable_amount,
                 :declaration_type_outputs,
                 to: :outputs
      end
    end
  end
end
