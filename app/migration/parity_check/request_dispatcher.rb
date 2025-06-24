module ParityCheck
  class RequestDispatcher
    include ActiveModel::Model
    include ActiveModel::Attributes

    class RunModeError < StandardError; end

    # Defines the order that requests are dispatch based on their
    # method and the number dispatched based on the run mode.
    REQUEST_PRIORITY_MODE = {
      %i[get] => {
        concurrent: 1_000,
        sequential: 1
      },
      %i[post put] => {
        concurrent: 1,
        sequential: 1
      }
    }.freeze

    attribute :run

    def dispatch
      Run.with_advisory_lock(run.id) do
        return if queued_or_in_progress_requests?

        finalise_run unless dispatch_requests.any?
      end
    end

  private

    def finalise_run
      run.complete!
      RunDispatcher.new.dispatch
    end

    def queued_or_in_progress_requests?
      run.requests.queued_or_in_progress.exists?
    end

    def dispatch_requests
      next_requests_to_dispatch.map do |request|
        request.queue!
        ParityCheckRequestJob.perform_later(request_id: request.id)
      end
    end

    def next_requests_to_dispatch
      # Look for pending requests in the order of REQUEST_PRIORITY_MODE
      # and return the amount we can dispatch based on the run mode.
      REQUEST_PRIORITY_MODE.lazy.map { |method, modes|
        limit = modes[run.mode.to_sym] || raise(RunModeError, "Run mode not recognized: #{run.mode}")
        run.requests.pending.with_method(method:).limit(limit)
      }.find(&:present?) || ParityCheck::Request.none
    end
  end
end
