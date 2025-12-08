RSpec.describe APISeedData::APITokens do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }
  let(:lead_providers) { FactoryBot.create_list(:lead_provider, 3) }

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }
  end

  describe "#plant" do
    it "creates API tokens for each lead provider" do
      expect { instance.plant }.to change(API::Token, :count).by(lead_providers.count)
    end

    it "does not create data when already present" do
      expect { instance.plant }.to change(API::Token, :count).by(lead_providers.count)
      expect { instance.plant }.not_to change(API::Token, :count)
    end

    it "logs the creation of API tokens" do
      instance.plant

      expect(logger).to have_received("level=").with(Logger::INFO)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter)

      expect(logger).to have_received(:info).with(/Planting api_tokens/).once
      LeadProvider.find_each do |lead_provider|
        token = lead_provider.name.parameterize
        expect(logger).to have_received(:info).with(/#{lead_provider.name}.*#{token}'/).once
      end
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any API tokens" do
        expect { instance.plant }.not_to change(API::Token, :count)
      end
    end
  end
end
