class CallOffContract::Assignment < ApplicationRecord
  belongs_to :statement
  belongs_to :call_off_contract
  has_many :declarations, inverse_of: :call_off_contract_assignment
end
