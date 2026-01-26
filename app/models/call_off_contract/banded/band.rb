class CallOffContract::Banded::Band < ApplicationRecord
  self.table_name = :call_off_contract_banded_bands

  belongs_to :banded_contract, class_name: "CallOffContract::Banded", inverse_of: :bands
end
