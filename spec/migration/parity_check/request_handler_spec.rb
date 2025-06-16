RSpec.describe ParityCheck::RequestHandler do
  let(:request) { FactoryBot.create(:parity_check_request) }
  let(:instance) { described_class.new(request) }
  let(:enabled) { true }

  before { allow(Rails.application.config).to receive(:parity_check).and_return({ enabled: }) }

  it "has the correct attributes" do
    expect(instance).to have_attributes(request:)
  end

  describe "#process_request" do
    subject(:process_request) { instance.process_request }

    it "calls the client to perform requests and persists the response" do
      client = instance_double(ParityCheck::Client)
      allow(ParityCheck::Client).to receive(:new).with(request:).and_return(client)

      response = FactoryBot.build(:parity_check_response, request: nil)
      allow(client).to receive(:perform_requests).and_yield(response)

      expect { process_request }.to change(response, :request).from(nil).to(request)
      expect(response).to be_persisted
    end

    context "when parity check is disabled" do
      let(:enabled) { false }

      it { expect { process_request }.to raise_error(described_class::UnsupportedEnvironmentError, "The parity check functionality is disabled for this environment") }
    end
  end
end
