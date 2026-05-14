RSpec.describe ContractPeriods::SeedFromPrevious do
  subject(:service) { described_class.new(contract_period:) }

  let(:current_year) { Time.zone.today.year }
  let(:previous_year) { current_year - 1 }
  let(:next_year) { current_year + 1 }

  describe "#initialize" do
    context "when :contract_period is nil" do
      let(:contract_period) { nil }

      it do
        expect { service }.to raise_error(ArgumentError, "Contract period is required")
      end
    end
  end

  describe "#schedule!" do
    let(:contract_period) do
      FactoryBot.create(:contract_period,
                        year: current_year)
    end

    context "without a previous contract period" do
      it do
        expect { service.schedule! }.to raise_error(
          ContractPeriods::SeedFromPrevious::NoPreviousContractPeriodError,
          "No previous contract period found"
        )
      end
    end

    context "with a previous contract period" do
      let(:previous_contract_period) do
        FactoryBot.create(:contract_period,
                          year: previous_year)
      end

      let!(:previous_schedule_september) do
        FactoryBot.create(:schedule,
                          contract_period: previous_contract_period,
                          identifier: "ecf-standard-september")
      end

      let(:new_schedule) { Schedule.find_by(contract_period_year: current_year) }

      before do
        previous_schedule_september.milestones.create!(
          declaration_type: "started",
          start_date: Date.new(previous_year, 6, 1),
          milestone_date: Date.new(previous_year, 11, 30)
        )
        previous_schedule_september.milestones.create!(
          declaration_type: "retained-1",
          start_date: Date.new(previous_year, 9, 1),
          milestone_date: nil
        )
      end

      context "when the contract period has not started yet" do
        before do
          travel_to 1.day.before(contract_period.started_on)
        end

        it "returns :scheduled" do
          expect(service.schedule!).to eq(:scheduled)
        end

        it "clones from the previous contract period" do
          expect { service.schedule! }.to change(Schedule, :count).by(1).and change(Milestone, :count).by(2)
        end

        it "raises an error if called repeatedly" do
          expect(service.schedule!).to eq(:scheduled)
          expect { service.schedule! }.to raise_error(
            ContractPeriods::SeedFromPrevious::AlreadyScheduledError,
            "The contract period already has schedules"
          )
        end

        it "advances dates by one year if set" do
          service.schedule!
          expect(new_schedule.milestones.find_by(declaration_type: "started").start_date).to eq(Date.new(current_year, 6, 1))

          expect(new_schedule.milestones.find_by(declaration_type: "started").milestone_date).to eq(Date.new(current_year, 11, 30))
          expect(new_schedule.milestones.find_by(declaration_type: "retained-1").milestone_date).to be_nil
        end

        it "rolls back changes if an error occurs" do
          allow(Milestone).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
          expect { service.schedule! }.to raise_error(ActiveRecord::RecordInvalid)
          expect(new_schedule).to be_nil
        end

        it "copies the schedule identifier" do
          service.schedule!
          expect(new_schedule.identifier).to eq("ecf-standard-september")
        end

        it "creates milestones with declaration types copied" do
          service.schedule!
          expect(new_schedule.milestones.pluck(:declaration_type)).to contain_exactly("started", "retained-1")
        end
      end

      context "when the contract period starts today" do
        before do
          travel_to contract_period.started_on
        end

        it do
          expect { service.schedule! }.to raise_error(
            ContractPeriods::SeedFromPrevious::ContractPeriodStartedError,
            "Contract periods cannot be scheduled after they have started"
          )
        end
      end

      context "when the contract period has already started" do
        before do
          travel_to 1.day.after(contract_period.started_on)
        end

        it do
          expect { service.schedule! }.to raise_error(
            ContractPeriods::SeedFromPrevious::ContractPeriodStartedError,
            "Contract periods cannot be scheduled after they have started"
          )
        end
      end

      context "when schedules already exist for the contract period" do
        before do
          FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-september")
          travel_to 1.day.before(contract_period.started_on)
        end

        it do
          expect { service.schedule! }.to raise_error(
            ContractPeriods::SeedFromPrevious::AlreadyScheduledError,
            "The contract period already has schedules"
          )
        end
      end
    end
  end
end
