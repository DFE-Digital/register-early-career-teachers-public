module CallOffContract
  class Banded::Band < ApplicationRecord
    self.table_name = :call_off_contract_banded_bands

    belongs_to :call_off_contract_banded, class_name: "CallOffContract::Banded", inverse_of: :bands
  end
end
