class CallOffContract < ApplicationRecord
  has_many :assignments, class_name: "CallOffContract::Assignment", inverse_of: :call_off_contract

  delegated_type :contractable, types: %w[CallOffContract::Banded CallOffContract::FlatRate]
end
