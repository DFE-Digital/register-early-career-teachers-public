module ParityCheck
  class RequestBenchmark < Faraday::Middleware
    def on_request(env)
      env[:request_start_time] = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def on_complete(env)
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      start_time = env[:request_start_time]
      duration_ms = (end_time - start_time) * 1_000

      env[:request_duration_ms] = duration_ms
    end
  end
end
