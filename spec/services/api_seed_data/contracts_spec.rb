RSpec.describe APISeedData::Contracts do
  let(:verbose) { true }
  let(:instance) { described_class.new(verbose:) }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }
  end

  describe "#plant" do
    let(:mentor_funding_contract_period) { FactoryBot.create(:contract_period, year: 2025, mentor_funding_enabled: true) }
    let!(:mentor_funding_framework_agreement) { FactoryBot.create(:framework_agreement, contract_period: mentor_funding_contract_period) }

    let(:contract_period) { FactoryBot.create(:contract_period, year: 2024, mentor_funding_enabled: false) }
    let!(:framework_agreement) { FactoryBot.create(:framework_agreement, contract_period:) }

    it "creates contracts for framework agreements with the correct attributes" do
      expect { instance.plant }.to change(framework_agreement.contracts, :count).by_at_least(1)
        .and change(mentor_funding_framework_agreement.contracts, :count).by_at_least(1)

      expect(framework_agreement.contracts).to all have_attributes(contract_type: "ecf")
      expect(mentor_funding_framework_agreement.contracts).to all have_attributes(contract_type: "ittecf_ectp")
    end

    it "logs the creation of contracts" do
      instance.plant

      expect(logger).to have_received("level=").with(Logger::INFO)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter)

      expect(logger).to have_received(:info).with(/Planting contracts/).once

      expect(logger).to have_received(:info).with(/#{framework_agreement.lead_provider.name} contracts/).once
      expect(logger).to have_received(:info).with(/Contracts for #{framework_agreement.contract_period.year}: \d+ ECF/).once

      expect(logger).to have_received(:info).with(/#{mentor_funding_framework_agreement.lead_provider.name} contracts/).once
      expect(logger).to have_received(:info).with(/Contracts for #{mentor_funding_framework_agreement.contract_period.year}: \d+ ITTECF ECTP/).once
    end

    context "when verbose logging is false" do
      let(:verbose) { false }

      it "does not log the creation of contracts" do
        instance.plant

        expect(logger).to have_received(:info).with(/Planting contracts/).once
        expect(logger).not_to have_received(:info).with(/#{framework_agreement.lead_provider.name}/)
        expect(logger).not_to have_received(:info).with(/#{mentor_funding_framework_agreement.lead_provider.name}/)
      end
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any contracts" do
        expect { instance.plant }.not_to change(Contract, :count)
      end
    end
  end
end
