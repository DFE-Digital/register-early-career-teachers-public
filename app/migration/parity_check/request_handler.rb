module ParityCheck
  class RequestHandler
    include ParityCheck::Configuration

    attr_reader :request

    def initialize(request)
      @request = request
    end

    def process_request
      ensure_parity_check_enabled!

      client.perform_requests { |response| response.update!(request:) }
    end

  private

    def client
      @client ||= Client.new(request:)
    end
  end
end
