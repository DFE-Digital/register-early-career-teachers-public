module ParityCheck
  class RunDispatcher
    def dispatch
      Run.with_advisory_lock("dispatch_run") do
        dispatch_next_run unless in_progress_run?
      end
    end

  private

    def in_progress_run?
      Run.in_progress.exists?
    end

    def dispatch_next_run
      next_run_to_dispatch&.tap do |run|
        run.in_progress!
        ParityCheck::RequestDispatcher.new(run:).dispatch
      end
    end

    def next_run_to_dispatch
      Run.pending.first
    end
  end
end
