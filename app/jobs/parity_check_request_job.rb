class ParityCheckRequestJob < ApplicationJob
  queue_as :parity_check_requests

  def perform(request_id:)
    request = ParityCheck::Request.find_by(id: request_id)
    ParityCheck::RequestHandler.new(request).process_request if request
  end
end
