RSpec.describe ParityCheck::Runner, type: :model do
  let(:endpoints) do
    [
      FactoryBot.create(:parity_check_endpoint, method: :get, path: "/test-path"),
      FactoryBot.create(:parity_check_endpoint, method: :post, path: "/test-other-path"),
    ]
  end
  let(:mode) { "sequential" }
  let(:endpoint_ids) { endpoints.map(&:id) }
  let(:enabled) { true }
  let!(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:instance) { described_class.new(endpoint_ids:, mode:) }

  before { allow(Rails.application.config).to receive(:parity_check).and_return({ enabled: }) }

  it "has the correct attributes" do
    expect(instance).to have_attributes(endpoint_ids:)
    expect(instance).to have_attributes(mode:)
  end

  describe "defaults" do
    it { is_expected.to have_attributes(mode: :concurrent) }
  end

  describe "validations" do
    subject { instance }

    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:endpoint_ids).with_message("Select at least one endpoint.") }
    it { is_expected.to validate_presence_of(:mode) }
    it { is_expected.to validate_inclusion_of(:mode).in_array(%w[concurrent sequential]) }

    it "validates that all endpoints exist" do
      endpoints.first.destroy!
      expect(instance).not_to be_valid
      expect(instance.errors[:endpoint_ids]).to include("One or more selected endpoints do not exist.")
    end

    it "validates that there is at least one lead provider" do
      LeadProvider.destroy_all
      expect(instance).not_to be_valid
      expect(instance.errors[:base]).to include("There are no lead providers available; create at least one lead provider to run a parity check.")
    end
  end

  describe "#run!" do
    subject(:run) { instance.run! }

    it "creates a pending run of the correct mode" do
      created_run = nil
      expect { created_run = run }.to change(ParityCheck::Run, :count).by(1)
      expect(created_run).to be_pending
      expect(created_run.mode).to eq(mode)
    end

    it "creates a request for each lead provider and endpoint, ignoring lead providers without an ecf_id" do
      other_lead_provider = FactoryBot.create(:lead_provider)
      FactoryBot.create(:lead_provider, ecf_id: nil) # Ignored due to ecf_id being nil
      lead_providers = [lead_provider, other_lead_provider]

      created_run = nil
      expect { created_run = run }.to change(ParityCheck::Request, :count).by(lead_providers.count * endpoints.size)

      expect(created_run.requests).to include(
        have_attributes(lead_provider:, endpoint: endpoints[0]),
        have_attributes(lead_provider: other_lead_provider, endpoint: endpoints[0]),
        have_attributes(lead_provider:, endpoint: endpoints[1]),
        have_attributes(lead_provider: other_lead_provider, endpoint: endpoints[1])
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

  describe "#endpoint_ids=" do
    subject { instance.endpoint_ids }

    let(:endpoint_ids) { ["", "123", nil, "456"] }

    it { is_expected.to contain_exactly("123", "456") }
  end
end
