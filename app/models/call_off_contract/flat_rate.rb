class CallOffContract::FlatRate < ApplicationRecord
  include Contractable

  self.table_name = :call_off_contract_flat_rates
end
