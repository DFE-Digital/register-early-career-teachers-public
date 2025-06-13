class ParityCheckJob < ApplicationJob
  queue_as :parity_check

  def perform(endpoint_ids:)
    endpoints = ParityCheck::Endpoint.where(id: endpoint_ids)
    ParityCheck::Runner.new(endpoints).run
  end
end
