RSpec.describe APISeedData::ParityChecks do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }
  let!(:lead_provider) { FactoryBot.create(:lead_provider) }

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }

    allow(Rails.application.config).to receive(:parity_check).and_return({ enabled: true })
  end

  describe "#plant" do
    it "creates parity check data" do
      allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.3).and_return(true, false)
      allow(Faker::Boolean).to receive(:boolean).with(true_ratio: 0.4).and_return(true, false)

      instance.plant

      expect(ParityCheck::Endpoint).to be_exists

      expect(ParityCheck::Run.count).to eq(described_class::NUMBER_OF_RUNS)
      expect(ParityCheck::Run.failed).to be_exists
      expect(ParityCheck::Run.completed).to be_exists
      expect(ParityCheck::Run.where(mode: :concurrent)).to be_exists
      expect(ParityCheck::Run.where(mode: :sequential)).to be_exists

      expect(ParityCheck::Request).to be_exists
      expect(ParityCheck::Request.failed).to be_exists
      expect(ParityCheck::Request.completed).to be_exists

      expect(ParityCheck::Response).to be_exists
      expect(ParityCheck::Response.different).to be_exists
      expect(ParityCheck::Response.matching).to be_exists
    end

    it "does not create data when already present" do
      expect { instance.plant }.to change(ParityCheck::Run, :count)
      expect { instance.plant }.not_to change(ParityCheck::Run, :count)
    end

    it "logs the creation of parity check runs" do
      instance.plant

      expect(logger).to have_received("level=").with(Logger::INFO)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter)

      expect(logger).to have_received(:info).with(/Planting parity_checks/).once
      ParityCheck::Endpoint.find_each do |endpoint|
        expect(logger).to have_received(:info).with(/#{Regexp.escape(endpoint.human_readable_url)}/).at_least(:once)
      end

      expect(logger).to have_received(:info).with(/Concurrent, *\d+ requests, -?\d+\.?\d*x performance gain, \d+% match rate/).at_least(:once)
      expect(logger).to have_received(:info).with(/Sequential, *\d+ requests, -?\d+\.?\d*x performance gain, \d+% match rate/).at_least(:once)
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any parity check data" do
        instance.plant

        expect(ParityCheck::Endpoint).not_to be_exists
        expect(ParityCheck::Run).not_to be_exists
        expect(ParityCheck::Request).not_to be_exists
        expect(ParityCheck::Response).not_to be_exists
      end
    end
  end
end
