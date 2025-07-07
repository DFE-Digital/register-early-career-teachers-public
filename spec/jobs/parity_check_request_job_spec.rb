RSpec.describe ParityCheckRequestJob, type: :job do
  describe "#perform" do
    it "calls the ParityCheck::RequestHandler service with the request" do
      request = create(:parity_check_request)
      request_handler = instance_double(ParityCheck::RequestHandler)

      allow(ParityCheck::RequestHandler).to receive(:new).with(request).and_return(request_handler)
      expect(request_handler).to receive(:process_request)

      described_class.new.perform(request_id: request.id)
    end

    it "does not call the handler if the request cannot be found" do
      expect(ParityCheck::RequestHandler).not_to receive(:new)

      described_class.new.perform(request_id: 123)
    end
  end
end
