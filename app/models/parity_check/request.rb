module ParityCheck
  class Request < ApplicationRecord
    self.table_name = "parity_check_requests"

    include Completable

    belongs_to :run
    belongs_to :lead_provider

    validates :lead_provider, presence: true
    validates :run, presence: true
    validates :path, presence: true
    validates :method, presence: true, inclusion: { in: %w[get post put] }
  end
end
