module ParityCheck
  class Request < ApplicationRecord
    self.table_name = "parity_check_requests"

    include Completable

    belongs_to :run
    belongs_to :lead_provider
    belongs_to :endpoint
    has_many :responses

    validates :lead_provider, presence: true
    validates :run, presence: true
    validates :endpoint, presence: true
  end
end
