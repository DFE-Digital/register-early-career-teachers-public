module Admin
  module Statements
    class OutputPaymentsComponent < ApplicationComponent
      class BasePresenter < SimpleDelegator
        delegate :total_billable_amount, to: :outputs
        delegate :declaration_type_outputs, to: :outputs, private: true
      end
    end
  end
end
