RSpec.describe APISeedData::Contracts do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }
  end

  describe "#plant" do
    let(:mentor_funding_contract_period) { FactoryBot.create(:contract_period, year: 2025, mentor_funding_enabled: true) }
    let!(:mentor_funding_active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period: mentor_funding_contract_period) }

    let(:contract_period) { FactoryBot.create(:contract_period, year: 2024, mentor_funding_enabled: false) }
    let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }

    it "creates contracts for active lead providers with the correct attributes" do
      expect { instance.plant }.to change(active_lead_provider.contracts, :count).by_at_least(1)
        .and change(mentor_funding_active_lead_provider.contracts, :count).by_at_least(1)

      expect(active_lead_provider.contracts).to all have_attributes(contract_type: "ecf")
      expect(mentor_funding_active_lead_provider.contracts).to all have_attributes(contract_type: "ittecf_ectp")
    end

    it "logs the creation of contracts" do
      instance.plant

      expect(logger).to have_received("level=").with(Logger::INFO)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter)

      expect(logger).to have_received(:info).with(/Planting contracts/).once

      expect(logger).to have_received(:info).with(/#{active_lead_provider.lead_provider.name} contracts/).once
      expect(logger).to have_received(:info).with(/Contracts for #{active_lead_provider.contract_period.year}: \d+ ECF/).once

      expect(logger).to have_received(:info).with(/#{mentor_funding_active_lead_provider.lead_provider.name} contracts/).once
      expect(logger).to have_received(:info).with(/Contracts for #{mentor_funding_active_lead_provider.contract_period.year}: \d+ ITTECF ECTP/).once
    end

    it "does not create data when already present" do
      expect { instance.plant }.to change(Contract, :count)
      expect { instance.plant }.not_to change(Contract, :count)
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any contracts" do
        expect { instance.plant }.not_to change(Contract, :count)
      end
    end
  end
end
