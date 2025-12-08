RSpec.describe APISeedData::Teachers::SchoolTransfers do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }
  let!(:active_lead_providers) { FactoryBot.create_list(:active_lead_provider, 3) }
  let(:lead_provider1) { active_lead_providers.first.lead_provider }
  let(:lead_provider2) { active_lead_providers.second.lead_provider }
  let(:lead_provider3) { active_lead_providers.third.lead_provider }

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }
    stub_const("#{described_class}::MIN_SET_OF_TRANSFERS_SCENARIOS_PER_LP", 1)
  end

  describe "#plant" do
    subject(:plant) { instance.plant }

    it "creates the school transfers for each lead provider" do
      plant
      refresh_teacher_metadata

      expect(school_transfers_for(lead_provider1)).not_to be_empty
      expect(school_transfers_for(lead_provider2)).not_to be_empty
      expect(school_transfers_for(lead_provider3)).not_to be_empty
    end

    it "does not create data when already present" do
      expect { instance.plant }.to change(TrainingPeriod, :count)
      refresh_teacher_metadata
      expect { instance.plant }.not_to change(TrainingPeriod, :count)
    end
  end

private

  def refresh_teacher_metadata
    Teacher.find_each { Metadata::Handlers::Teacher.new(it).refresh_metadata! }
  end

  def school_transfers_for(lead_provider)
    API::Teachers::SchoolTransfers::Query
      .new(lead_provider_id: lead_provider.id)
      .school_transfers
  end
end
