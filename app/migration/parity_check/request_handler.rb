module ParityCheck
  class RequestHandler
    include ParityCheck::Configuration

    attr_reader :request

    delegate :run, to: :request

    def initialize(request)
      @request = request
    end

    def process_request
      ensure_parity_check_enabled!

      request.start!

      client.perform_requests

      request.complete!
    rescue Client::Error
      request.halt!
      raise # We want the job to fail to retain the error for debugging.
    ensure
      RequestDispatcher.new(run:).dispatch
    end

  private

    def client
      @client ||= Client.new(request:)
    end
  end
end
