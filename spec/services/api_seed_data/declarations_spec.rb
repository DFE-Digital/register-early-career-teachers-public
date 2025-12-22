RSpec.describe APISeedData::Declarations do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }

  let(:ect_school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: 2023) }
  let(:ect_training_period) { FactoryBot.create(:training_period, :for_ect, school_partnership: ect_school_partnership) }
  let!(:ect_active_lead_provider) { ect_training_period.school_partnership.active_lead_provider }

  let(:mentor_school_partnership) { FactoryBot.create(:school_partnership, :for_year, year: 2023) }
  let(:mentor_training_period) { FactoryBot.create(:training_period, :for_mentor, school_partnership: mentor_school_partnership) }
  let!(:mentor_active_lead_provider) { mentor_training_period.school_partnership.active_lead_provider }

  before do
    stub_const("#{described_class}::MAX_TEACHERS_WITH_DECLARATIONS", 1)

    allow(Rails).to receive(:env) { environment.inquiry }
    ignored_logger = instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil)
    allow(Logger).to receive(:new).with($stdout) { ignored_logger }

    APISeedData::ContractPeriods.new.plant
    APISeedData::Statements.new.plant
    APISeedData::SchedulesAndMilestones.new.plant

    allow(Logger).to receive(:new).with($stdout) { logger }
  end

  describe "#plant" do
    subject(:plant) { instance.plant }

    it "does not create data when already present" do
      expect { instance.plant }.to change(Declaration, :count)
      expect { instance.plant }.not_to change(Declaration, :count)
    end

    it "creates declarations for both ECT and mentor teachers" do
      plant

      expect(Declaration.where(training_period: ect_training_period)).to exist
      expect(Declaration.where(training_period: mentor_training_period)).to exist
    end

    it "creates declarations for all lead providers" do
      plant

      active_lead_providers = Declaration.all.map do |declaration|
        declaration.training_period.school_partnership.active_lead_provider
      end

      expect(active_lead_providers.uniq.size).to be > 1
    end

    it "logs the creation of declaration records" do
      plant

      expect(logger).to have_received("level=").with(Logger::INFO)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter)

      expect(logger).to have_received(:info).with(/Planting declarations/).once

      expect(logger).to have_received(:info).with(/#{ect_active_lead_provider.lead_provider.name} - ect/).once
      expect(logger).to have_received(:info).with(/#{mentor_active_lead_provider.lead_provider.name} - mentor/).once

      types = Declaration.declaration_types.keys
      statuses = Declaration.payment_statuses.keys + Declaration.clawback_statuses.keys

      expect(logger).to have_received(:info).with(/(#{types.join('|')}) - (#{statuses.join('|')}) - \d+-\d+-\d+/).at_least(:once)
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any declarations" do
        expect { instance.plant }.not_to change(Declaration, :count)
      end
    end
  end
end
