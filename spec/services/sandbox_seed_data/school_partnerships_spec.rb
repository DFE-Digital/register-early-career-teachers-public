RSpec.describe SandboxSeedData::SchoolPartnerships do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }
  end

  describe "#plant" do
    let(:contract_period) { FactoryBot.create(:contract_period) }
    let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }

    # Ensure there are schools to create partnerships with
    before do
      FactoryBot.create_list(:lead_provider_delivery_partnership, 10, active_lead_provider:)
      FactoryBot.create_list(:school, 100)
    end

    it "creates the correct quantity of school partnerships" do
      instance.plant

      expect(SchoolPartnership.all.size).to eq(described_class::NUMBER_OF_RECORDS)
    end

    it "logs the creation of school partnerships" do
      instance.plant

      expect(logger).to have_received("level=").with(Logger::INFO)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter)

      expect(logger).to have_received(:info).with(/Planting school partnerships/).once

      school_partnership = SchoolPartnership.all.sample
      expect(logger).to have_received(:info).with(/#{school_partnership.school.urn}/).at_least(:once)
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any school partnerships" do
        expect { instance.plant }.not_to change(ContractPeriod, :count)
      end
    end
  end
end
