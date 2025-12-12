RSpec.describe APISeedData::UnfundedMentors, :with_metadata do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }
  let!(:school) { FactoryBot.create(:school) }
  let!(:active_lead_providers) { FactoryBot.create_list(:active_lead_provider, 2) }
  let!(:school_partnerships) do
    active_lead_providers.map do |alp|
      lpdp = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: alp)

      FactoryBot.create(
        :school_partnership,
        school:,
        lead_provider_delivery_partnership: lpdp
      )
    end
  end

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }

    stub_const("#{described_class}::MIN_UNFUNDED_MENTORS_PER_LP", 2)
  end

  describe "#plant" do
    subject(:plant) { instance.plant }

    it "creates the correct quantity of unfunded mentors per Lead provider" do
      plant

      LeadProvider.find_each do |lead_provider|
        expect(API::Teachers::UnfundedMentors::Query.new(lead_provider_id: lead_provider.id).unfunded_mentors.size).to eq(2)
      end
    end

    it "does not create data when already present" do
      expect { instance.plant }.to change(Teacher, :count)
      expect { instance.plant }.not_to change(Teacher, :count)
    end

    it "logs the creation of unfunded mentors" do
      plant

      expect(logger).to have_received("level=").with(Logger::INFO)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter)

      expect(logger).to have_received(:info).with(/Planting unfunded mentors/).once

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
