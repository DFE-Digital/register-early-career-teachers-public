RSpec.describe SandboxSeedData::ContractPeriods do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }
  end

  describe "#plant" do
    it "creates contract_periods with correct attributes" do
      instance.plant

      described_class::DATA.each do |data|
        expect(ContractPeriod.find_by!(year: data[:year])).to have_attributes(
          enabled: data[:enabled],
          started_on: Date.new(data[:year], 6, 1),
          finished_on: Date.new(data[:year] + 1, 5, 31),
          payments_frozen_at: data[:payments_frozen_at]
        )
      end
    end

    it "does not create data when already present" do
      expect { instance.plant }.to change(ContractPeriod, :count).by(described_class::DATA.count)
      expect { instance.plant }.not_to change(ContractPeriod, :count)
    end

    it "logs the creation of contract_periods" do
      instance.plant

      expect(logger).to have_received("level=").with(Logger::INFO)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter)

      expect(logger).to have_received(:info).with(/Planting contract_periods/).once
      expect(logger).to have_received(:info).with(/#{described_class::DATA.map(&:keys).sample}/).at_least(:once)
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any contract_periods" do
        expect { instance.plant }.not_to change(ContractPeriod, :count)
      end
    end
  end
end
