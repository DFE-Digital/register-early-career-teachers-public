module CallOffContract
  class FlatRate < ApplicationRecord
    self.table_name = :call_off_contract_flat_rates

    has_many :assignments, class_name: "CallOffContract::Assignment", inverse_of: :call_off_contract_flat_rate
  end
end
