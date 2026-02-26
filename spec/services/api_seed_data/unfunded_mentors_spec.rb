RSpec.describe APISeedData::UnfundedMentors, :with_metadata do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }

  let(:contract_period_2024) { FactoryBot.create(:contract_period, year: 2024) }
  let(:contract_period_2025) { FactoryBot.create(:contract_period, year: 2025) }

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }

    stub_const("#{described_class}::MIN_UNFUNDED_MENTORS_PER_LP", 2)

    # Create support data
    FactoryBot.create_list(:lead_provider, 2).each do |lead_provider|
      FactoryBot.create_list(:lead_provider_delivery_partnership, 2, :for_year, lead_provider:, year: contract_period_2024.year)
      FactoryBot.create_list(:lead_provider_delivery_partnership, 2, :for_year, lead_provider:, year: contract_period_2025.year)
    end
    APISeedData::Schools.new.plant
    APISeedData::SchoolPartnerships.new.plant
    APISeedData::SchedulesAndMilestones.new.plant
  end

  describe "#plant" do
    subject(:plant) { instance.plant }

    it "creates the correct quantity of unfunded mentors per Lead provider" do
      plant

      LeadProvider.find_each do |lead_provider|
        expect(API::Teachers::UnfundedMentors::Query.new(lead_provider_id: lead_provider.id).unfunded_mentors.size).to eq(2)
      end
    end

    it "creates unfunded mentors accross the contract periods" do
      plant

      LeadProvider.find_each do |lead_provider|
        expect(API::Teachers::UnfundedMentors::Query.new(lead_provider_id: lead_provider.id).unfunded_mentors.map { |unfunded_mentor|
          unfunded_mentor = Teacher.find(unfunded_mentor.id)
          unfunded_mentor.latest_mentor_at_school_period.latest_training_period.contract_period.year
        }.uniq.size).to be > 1
      end
    end

    it "does not create data when already present" do
      expect { instance.plant }.to change(Teacher, :count)
      expect { instance.plant }.not_to change(Teacher, :count)
    end

    it "logs the creation of unfunded mentors" do
      plant

      expect(logger).to have_received("level=").with(Logger::INFO).at_least(:once)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter).at_least(:once)

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
