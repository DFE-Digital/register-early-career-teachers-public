class ParityCheckRequestJob < ApplicationJob
  queue_as :parity_check_requests

  def perform(request_id:)
    request = ParityCheck::Request.find_by(id: request_id)

    if request
      clear_state_if_retrying!(request:)
      ParityCheck::RequestHandler.new(request).process_request
    end
  end

private

  def clear_state_if_retrying!(request:)
    # If the request job failed it will be in an in-progress state
    # when the job is retried.
    return unless request.in_progress?

    request.responses.destroy_all
    request.update!(state: :queued)
  end
end
