RSpec.describe ParityCheckRequestJob, type: :job do
  describe "#perform" do
    let(:request_handler) { instance_double(ParityCheck::RequestHandler) }

    it "calls the ParityCheck::RequestHandler service with the request" do
      request = FactoryBot.create(:parity_check_request)

      allow(ParityCheck::RequestHandler).to receive(:new).with(request).and_return(request_handler)
      expect(request_handler).to receive(:process_request)

      described_class.new.perform(request_id: request.id)
    end

    it "does not call the handler if the request cannot be found" do
      expect(ParityCheck::RequestHandler).not_to receive(:new)

      described_class.new.perform(request_id: 123)
    end

    it "clears existing responses and resets the request status to queued if retrying a request" do
      request = FactoryBot.create(:parity_check_request, :in_progress)
      FactoryBot.create(:parity_check_response, request:)

      allow(ParityCheck::RequestHandler).to receive(:new).with(request).and_return(request_handler)
      expect(request_handler).to receive(:process_request)

      described_class.new.perform(request_id: request.id)

      request.reload

      expect(request.responses).to be_empty
      expect(request).to be_queued
    end
  end
end
