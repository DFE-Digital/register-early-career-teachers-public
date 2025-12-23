RSpec.describe APISeedData::PersonaUsers do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }
  let(:personas_yml) { YAML.load_file(Rails.root.join("config/personas.yml")) }

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }
  end

  describe "#plant" do
    it "creates persona users for admin dashboard access" do
      expect { instance.plant }.to change(User, :count).by(3)
    end

    it "does not create data when already present" do
      expect { instance.plant }.to change(User, :count).by(3)
      expect { instance.plant }.not_to change(User, :count)
    end

    it "logs the creation of persona users" do
      instance.plant

      expect(logger).to have_received("level=").with(Logger::INFO)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter)

      expect(logger).to have_received(:info).with(/Planting persona users/).once
      expect(logger).to have_received(:info).with(/#{personas_yml.select { |p| p['type'] == 'DfE staff' }.sample['name']}/).once
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any persona users" do
        expect { instance.plant }.not_to change(User, :count)
      end
    end
  end
end
