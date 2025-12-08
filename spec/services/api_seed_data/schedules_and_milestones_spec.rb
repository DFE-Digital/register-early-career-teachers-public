RSpec.describe APISeedData::SchedulesAndMilestones do
  let(:instance) { described_class.new }
  let(:environment) { "sandbox" }
  let(:logger) { instance_double(Logger, info: nil, "formatter=" => nil, "level=" => nil) }

  before do
    allow(Logger).to receive(:new).with($stdout) { logger }
    allow(Rails).to receive(:env) { environment.inquiry }

    APISeedData::ContractPeriods.new.plant
  end

  describe "#plant" do
    it "creates schedules and milestones for all contract periods" do
      instance.plant

      ContractPeriod.find_each do |contract_period|
        schedules = Schedule.where(contract_period:)
        expect(schedules).to be_exists
        schedules.each do |schedule|
          expect(schedule.milestones).to be_exists
        end
      end
    end

    it "does not create data when already present" do
      expect { instance.plant }.to change(Schedule, :count).and change(Milestone, :count)
      expect { instance.plant }.not_to change(Schedule, :count)
      expect { instance.plant }.not_to change(Milestone, :count)
    end

    it "logs the creation of schedules and milestones" do
      instance.plant

      expect(logger).to have_received("level=").with(Logger::INFO).at_least(:once)
      expect(logger).to have_received("formatter=").with(Rails.logger.formatter).at_least(:once)

      expect(logger).to have_received(:info).with(/Planting schedules_and_milestones/).once

      ContractPeriod.find_each do |contract_period|
        expect(logger).to have_received(:info).with(/Added schedule.*#{contract_period.year}.*ecf-(standard|reduced|extended|replacement)/).at_least(:once)
      end
    end

    context "when in the production environment" do
      let(:environment) { "production" }

      it "does not create any schedules or milestones" do
        expect { instance.plant }.not_to change(Schedule, :count)
        expect { instance.plant }.not_to change(Milestone, :count)
      end
    end
  end
end
