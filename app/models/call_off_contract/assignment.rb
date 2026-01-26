module CallOffContract
  class Assignment < ApplicationRecord
    self.table_name = :call_off_contract_assignments

    belongs_to :statement
    belongs_to :call_off_contract_banded, optional: true, class_name: "CallOffContract::Banded"
    belongs_to :call_off_contract_flat_rate, optional: true, class_name: "CallOffContract::FlatRate"

    enum :declaration_resolver_type,
         %w[all ect mentor].index_by(&:itself),
         prefix: true

    def call_off_contract
      call_off_contract_banded || call_off_contract_flat_rate
    end
  end
end
