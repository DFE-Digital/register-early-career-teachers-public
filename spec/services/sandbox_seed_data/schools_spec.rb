RSpec.describe SandboxSeedData::Schools do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }
  end

  describe "#plant" do
    let(:contract_period) { FactoryBot.create(:contract_period) }
    let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }

    it "creates the correct quantity of schools" do
      instance.plant

      expect(School.all.size).to eq(described_class::NUMBER_OF_RECORDS)
    end

    it "logs the creation of schools" do
      instance.plant

      expect(logger).to have_received("level=").with(Logger::INFO)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter)

      expect(logger).to have_received(:info).with(/Planting schools/).once
      expect(logger).to have_received(:info).with(/#{School.all.sample.urn}/).at_least(:once)
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any schools" do
        expect { instance.plant }.not_to change(ContractPeriod, :count)
      end
    end
  end
end
