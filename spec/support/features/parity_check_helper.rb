module ParityCheckHelper
  def perform_next_parity_check_request_job(ecf_url:, rect_url:)
    enqueued_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs

    next_job = enqueued_jobs.find { it[:job] == ParityCheckRequestJob }
    enqueued_jobs.delete(next_job)

    request_id = next_job.dig(:args, 0, "request_id")
    request = ParityCheck::Request.find(request_id)

    stub_request(request.endpoint.method, "#{ecf_url}#{request.endpoint.path}")
    stub_request(request.endpoint.method, "#{rect_url}#{request.endpoint.path}")

    ParityCheckRequestJob.perform_now(request_id:)
  end
end

RSpec.configure do |config|
  config.include ParityCheckHelper, type: :feature
end
