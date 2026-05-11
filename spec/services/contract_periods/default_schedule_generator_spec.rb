RSpec.describe ContractPeriods::DefaultScheduleGenerator, type: :model do
  subject(:service) { described_class.new(contract_period:) }

  let(:current_year) { Time.zone.today.year }
  let(:previous_year) { current_year - 1 }
  let(:next_year) { current_year + 1 }

  describe "#initialize" do
    context "when :contract_period is nil" do
      let(:contract_period) { nil }

      it "raises an error" do
        expect { service }.to raise_error(ArgumentError, "Contract period is required")
      end
    end
  end

  describe "#schedule!" do
    let(:contract_period) do
      FactoryBot.create(:contract_period, year: current_year)
    end

    context "when the contract period has not started yet" do
      before do
        travel_to 1.day.before(contract_period.started_on)
      end

      it "returns :created" do
        expect(service.schedule!).to eq(:created)
      end

      it "generates schedules and milestones" do
        expect { service.schedule! }.to change(Schedule, :count).and change(Milestone, :count)
      end

      it "can be called repeatedly" do
        expect(service.schedule!).to eq(:created)
        expect(service.schedule!).to eq(:already_scheduled)
      end
    end

    context "when the contract period starts today" do
      before do
        travel_to contract_period.started_on
      end

      it "returns :already_started" do
        expect(service.schedule!).to eq(:already_started)
      end

      it "does not generate schedules or milestones" do
        expect { service.schedule! }.not_to change(Schedule, :count)
        expect { service.schedule! }.not_to change(Milestone, :count)
      end
    end

    context "when the contract period has already started" do
      before do
        travel_to 1.day.after(contract_period.started_on)
      end

      it "returns :already_started" do
        expect(service.schedule!).to eq(:already_started)
      end

      it "does not generate schedules or milestones" do
        expect { service.schedule! }.not_to change(Schedule, :count)
        expect { service.schedule! }.not_to change(Milestone, :count)
      end
    end

    context "when schedules already exist for the contract period" do
      before do
        FactoryBot.create(:schedule, contract_period:, identifier: "ecf-standard-september")
        travel_to 1.day.before(contract_period.started_on)
      end

      it "returns :already_scheduled" do
        expect(service.schedule!).to eq(:already_scheduled)
      end

      it "does not generate schedules or milestones" do
        expect { service.schedule! }.not_to change(Schedule, :count)
        expect { service.schedule! }.not_to change(Milestone, :count)
      end

      it "can be called repeatedly" do
        expect(service.schedule!).to eq(:already_scheduled)
        expect(service.schedule!).to eq(:already_scheduled)
      end
    end

    context "without a previous contract period" do
      let(:current_year) { 2026 }
      let(:standard_schedules) { Schedule::STANDARD_SCHEDULE_IDENTIFIERS }
      let(:standard_declarations) { described_class::DECLARATION_TYPES_FOR_STANDARD }

      before do
        travel_to 1.day.before(contract_period.started_on)
      end

      it "returns :created" do
        expect(service.schedule!).to eq(:created)
      end

      it "creates common milestones for each standard schedule" do
        expect { service.schedule! }
          .to change(Schedule, :count).by(standard_schedules.size)
          .and change(Milestone, :count).by(standard_schedules.size * standard_declarations.size)
      end

      it "schedules milestones to start on the correct dates" do
        expect(Schedule.count).to be_zero
        service.schedule!

        generated_schedules_and_milestones = contract_period.schedules.map do |schedule|
          [
            schedule.contract_period_year.to_s,
            schedule.identifier,
            *schedule.milestones.map do |milestone|
              [milestone.declaration_type, milestone.start_date.to_s]
            end
          ]
        end

        expect(generated_schedules_and_milestones).to contain_exactly([
          "2026",
          "ecf-standard-september",
          %w[started 2026-06-01],
          %w[retained-1 2026-06-01],
          %w[retained-2 2026-06-01],
          %w[retained-3 2026-06-01],
          %w[retained-4 2026-06-01],
          %w[completed 2026-06-01]
        ], [
          "2026",
          "ecf-standard-january",
          %w[started 2027-01-01],
          %w[retained-1 2027-01-01],
          %w[retained-2 2027-01-01],
          %w[retained-3 2027-01-01],
          %w[retained-4 2027-01-01],
          %w[completed 2027-01-01]
        ], [
          "2026",
          "ecf-standard-april",
          %w[started 2027-04-01],
          %w[retained-1 2027-04-01],
          %w[retained-2 2027-04-01],
          %w[retained-3 2027-04-01],
          %w[retained-4 2027-04-01],
          %w[completed 2027-04-01]
        ])
      end
    end

    context "with a previous contract period" do
      let(:previous_contract_period) do
        FactoryBot.create(:contract_period, year: previous_year)
      end

      context "and a september schedule" do
        let!(:previous_schedule_september) do
          FactoryBot.create(:schedule, contract_period: previous_contract_period, identifier: "ecf-standard-september")
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

        it "returns :cloned" do
          expect(service.schedule!).to eq(:cloned)
        end

        it "creates a schedule for each previous schedule" do
          expect { service.schedule! }.to change(Schedule, :count).by(1)
        end

        it "copies the schedule identifier" do
          service.schedule!
          expect(new_schedule.identifier).to eq("ecf-standard-september")
        end

        it "creates milestones with declaration types copied" do
          service.schedule!
          expect(new_schedule.milestones.pluck(:declaration_type)).to contain_exactly("started", "retained-1")
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
          expect(Schedule.where(contract_period_year: current_year)).to be_none
        end

        context "and a january schedule" do
          let!(:previous_schedule_january) do
            FactoryBot.create(:schedule, contract_period: previous_contract_period, identifier: "ecf-standard-january")
          end
          let(:new_schedules) { Schedule.where(contract_period_year: current_year) }

          before do
            previous_schedule_january.milestones.create!(
              declaration_type: "started",
              start_date: Date.new(previous_year, 1, 1),
              milestone_date: Date.new(previous_year, 3, 31)
            )
          end

          it "creates all corresponding schedules" do
            expect { service.schedule! }.to change(Schedule, :count).by(2)
          end

          it "creates the correct identifiers" do
            service.schedule!
            expect(new_schedules.pluck(:identifier)).to contain_exactly(
              "ecf-standard-september",
              "ecf-standard-january"
            )
          end
        end
      end
    end

    context "with a previous contract period without schedules" do
      before do
        FactoryBot.create(:contract_period, year: previous_year)
      end

      it "returns :created" do
        expect(service.schedule!).to eq(:created)
      end

      it "behaves as if there were no previous contract period" do
        expect { service.schedule! }.to change(Schedule, :count).and change(Milestone, :count)
      end
    end
  end
end
