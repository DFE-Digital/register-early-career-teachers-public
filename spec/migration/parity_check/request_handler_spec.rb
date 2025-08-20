RSpec.describe ParityCheck::RequestHandler do
  let(:run) { FactoryBot.create(:parity_check_run, :in_progress) }
  let(:request) { FactoryBot.create(:parity_check_request, :queued, run:) }
  let(:instance) { described_class.new(request) }
  let(:enabled) { true }

  before { allow(Rails.application.config).to receive(:parity_check).and_return({ enabled: }) }

  it "has the correct attributes" do
    expect(instance).to have_attributes(request:)
  end

  describe "delegate methods" do
    subject { instance }

    it { is_expected.to delegate_method(:run).to(:request) }
  end

  describe "#process_request" do
    subject(:process_request) { instance.process_request }

    let(:client) { instance_double(ParityCheck::Client) }
    let(:response) { FactoryBot.build(:parity_check_response, request: nil) }

    before do
      allow(ParityCheck::Client).to receive(:new).with(request:).and_return(client)
      allow(client).to receive(:perform_requests).and_yield(response)
    end

    it "calls the client to perform requests and persists the response" do
      expect { process_request }.to change(response, :request).from(nil).to(request)
      expect(response).to be_persisted
    end

    it "marks the request as started" do
      expect { process_request }.to change(request, :started_at).from(nil).to be_within(1.second).of(Time.zone.now)
    end

    it "marks the request as completed" do
      expect { process_request }.to change(request, :completed_at).from(nil).to be_within(1.second).of(Time.zone.now)
    end

    it "calls the request dispatcher" do
      dispatcher = instance_double(ParityCheck::RequestDispatcher)
      allow(ParityCheck::RequestDispatcher).to receive(:new).with(run: request.run).and_return(dispatcher)
      expect(dispatcher).to receive(:dispatch)

      process_request
    end

    context "when the Client raises an error" do
      before { allow(response).to receive(:update!).and_raise(ParityCheck::Client::Error, "An error occurred") }

      it "marks the request as failed" do
        expect { process_request }.to change(request, :state).to("failed").and raise_error(ParityCheck::Client::Error, "An error occurred")
      end

      it "calls the request dispatcher" do
        dispatcher = instance_double(ParityCheck::RequestDispatcher)
        allow(ParityCheck::RequestDispatcher).to receive(:new).with(run: request.run).and_return(dispatcher)
        expect(dispatcher).to receive(:dispatch)

        expect { process_request }.to raise_error(ParityCheck::Client::Error, "An error occurred")
      end
    end

    context "when parity check is disabled" do
      let(:enabled) { false }

      it { expect { process_request }.to raise_error(described_class::UnsupportedEnvironmentError, "The parity check functionality is disabled for this environment") }
    end
  end
end
