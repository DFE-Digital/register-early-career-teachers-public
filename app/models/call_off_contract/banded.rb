class CallOffContract::Banded < ApplicationRecord
  include Contractable

  self.table_name = :call_off_contract_banded

  has_many :bands, class_name: "CallOffContract::Banded::Band", inverse_of: :banded_contract

  def payment_calculator(declarations:)
    CallOffContracts::PaymentCalculators::Banded.new(self, declarations)
  end
end
