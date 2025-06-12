module ParityCheck
  class Run < ApplicationRecord
    self.table_name = "parity_check_runs"

    include Completable

    has_many :requests
  end
end
