RSpec.describe SandboxSeedData::Teachers do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, :info => nil, "formatter=" => nil, "level=" => nil) }

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }

    stub_const("#{described_class}::NUMBER_OF_RECORDS", 2)
  end

  describe "#plant" do
    subject(:plant) { instance.plant }

    it { expect { plant }.to change(Teacher, :count).by(2) }

    it "logs the creation of school partnerships" do
      plant

      expect(logger).to have_received("level=").with(Logger::INFO)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter)

      expect(logger).to have_received(:info).with(/Planting teachers/).once

      teacher = Teacher.all.sample
      expect(logger).to have_received(:info).with(/#{teacher.trs_first_name}/).at_least(:once)
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any teachers" do
        expect { instance.plant }.not_to change(Teacher, :count)
      end
    end
  end
end
