RSpec.describe ParityCheck::Runner do
  let(:endpoints) do
    [
      ParityCheck::Endpoint.new(method: :get, path: "/test-path"),
      ParityCheck::Endpoint.new(method: :post, path: "/test-other-path"),
    ]
  end

  let(:instance) { described_class.new(endpoints) }
  let(:enabled) { true }

  before { allow(Rails.application.config).to receive(:parity_check).and_return({ enabled: }) }

  it "has the correct attributes" do
    expect(instance).to have_attributes(endpoints:)
  end

  describe "#run" do
    subject(:run) { instance.run }

    it "creates a pending run" do
      created_run = nil
      expect { created_run = run }.to change(ParityCheck::Run, :count).by(1)
      expect(created_run).to be_pending
    end

    it "creates a request for each lead provider and endpoint" do
      lead_provider1 = FactoryBot.create(:lead_provider)
      lead_provider2 = FactoryBot.create(:lead_provider)
      lead_providers = [lead_provider1, lead_provider2]

      created_run = nil
      expect { created_run = run }.to change(ParityCheck::Request, :count).by(lead_providers.count * endpoints.size)

      expect(created_run.requests).to include(
        have_attributes(lead_provider: lead_provider1, endpoint: endpoints[0]),
        have_attributes(lead_provider: lead_provider2, endpoint: endpoints[0]),
        have_attributes(lead_provider: lead_provider1, endpoint: endpoints[1]),
        have_attributes(lead_provider: lead_provider2, endpoint: endpoints[1])
      )
    end

    it "calls the run dispatcher" do
      run_dispatcher = instance_double(ParityCheck::RunDispatcher, dispatch: nil)
      allow(ParityCheck::RunDispatcher).to receive(:new).and_return(run_dispatcher)

      run

      expect(run_dispatcher).to have_received(:dispatch)
    end

    context "when parity check is disabled" do
      let(:enabled) { false }

      it { expect { run }.to raise_error(described_class::UnsupportedEnvironmentError, "The parity check functionality is disabled for this environment") }
    end
  end
end
