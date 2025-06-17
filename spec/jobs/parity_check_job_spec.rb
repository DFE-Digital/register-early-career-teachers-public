RSpec.describe ParityCheckJob, type: :job do
  describe "#perform" do
    before do
      allow(Rails.application.config).to receive(:parity_check).and_return({ enabled: true })
      ParityCheck::SeedEndpoints.new.plant!
    end

    it "calls the ParityCheck::Runner service with the provided endpoints (ignoring any not found)" do
      endpoint_ids = ParityCheck::Endpoint.pluck(:id) + [-1]
      endpoints = ParityCheck::Endpoint.where(id: endpoint_ids)

      runner = instance_double(ParityCheck::Runner)
      allow(ParityCheck::Runner).to receive(:new).with(endpoints).and_return(runner)
      expect(runner).to receive(:run)

      described_class.new.perform(endpoint_ids:)
    end
  end
end
