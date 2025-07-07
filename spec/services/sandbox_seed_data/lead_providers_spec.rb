RSpec.describe SandboxSeedData::LeadProviders do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }
  let(:all_registration_years) { described_class::DATA.values.map(&:to_a).flatten }

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }
  end

  describe "#plant" do
    before do
      all_registration_years.uniq.each { |year| create(:contract_period, year:) }
    end

    it "creates lead providers and active lead providers with correct attributes" do
      instance.plant

      described_class::DATA.each do |name, active_years|
        lead_provider = LeadProvider.find_by(name:)
        expect(lead_provider).to be_present

        active_years.each do |year|
          active_lead_provider = ActiveLeadProvider.find_by(
            lead_provider:,
            contract_period: ContractPeriod.find_by!(year:)
          )
          expect(active_lead_provider).to be_present
        end
      end
    end

    it "does not create data when already present" do
      expect { instance.plant }.to change(LeadProvider, :count).by(described_class::DATA.count)
        .and change(ActiveLeadProvider, :count).by(all_registration_years.count)

      expect { instance.plant }.not_to change(LeadProvider, :count)
      expect { instance.plant }.not_to change(ActiveLeadProvider, :count)
    end

    it "logs the creation of lead providers" do
      instance.plant

      expect(logger).to have_received("level=").with(Logger::INFO)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter)

      expect(logger).to have_received(:info).with(/Planting lead providers/).once
      expect(logger).to have_received(:info).with(/#{described_class::DATA.keys.sample}/).once
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any lead providers" do
        expect { instance.plant }.not_to change(LeadProvider, :count)
      end
    end
  end
end
