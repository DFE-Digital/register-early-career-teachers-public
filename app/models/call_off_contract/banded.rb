module CallOffContract
  class Banded < ApplicationRecord
    self.table_name = :call_off_contract_bandeds

    has_many :assignments, class_name: "CallOffContract::Assignment", inverse_of: :call_off_contract_banded
    has_many :bands, class_name: "CallOffContract::Banded::Band", inverse_of: :call_off_contract_banded
  end
end
