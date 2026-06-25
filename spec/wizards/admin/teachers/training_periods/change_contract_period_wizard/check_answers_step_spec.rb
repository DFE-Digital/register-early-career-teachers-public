RSpec.describe Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::CheckAnswersStep do
  subject(:step) { described_class.new(wizard:) }

  let(:wizard) do
    instance_double(
      Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Wizard,
      store:,
      partnership_selection_required?: partnership_selection_required,
      training_period:,
      selected_contract_period:,
      selected_school_partnership:,
      author:
    )
  end
  let(:store) { FactoryBot.build(:session_repository) }
  let(:partnership_selection_required) { true }
  let(:today) { Date.new(2026, 2, 1) }
  let(:started_on) { today.next_month }
  let(:training_period) { instance_double(TrainingPeriod, started_on:) }
  let(:selected_contract_period) { instance_double(ContractPeriod, year: 2026) }
  let(:selected_school_partnership) { instance_double(SchoolPartnership) }
  let(:author) { Events::SystemAuthor.new }

  describe "#previous_step" do
    it "returns select partnership" do
      expect(step.previous_step).to eq(:select_partnership)
    end

    context "when the partnership selection is skipped" do
      let(:partnership_selection_required) { false }

      it "returns select contract period" do
        expect(step.previous_step).to eq(:select_contract_period)
      end
    end
  end

  describe "#save!" do
    let(:change_service) { instance_double(service_class) }

    before do
      store.contract_period_year = selected_contract_period.year

      allow(service_class).to receive(:new).with(
        training_period:,
        contract_period: selected_contract_period,
        school_partnership: selected_school_partnership,
        author:
      ).and_return(change_service)
    end

    around do |example|
      travel_to(today) { example.run }
    end

    shared_examples "maps service errors to validation errors" do
      context "when the training period is not supported" do
        before do
          allow(change_service).to receive(:change_contract_period!).and_raise(
            service_class::UnsupportedTrainingPeriodError
          )
        end

        it "adds an eligibility error" do
          expect(step.save!).to be(false)
          expect(step.errors[:base]).to include("Training period is not eligible for contract period change")
        end
      end

      context "when the training period has no matching schedule" do
        before do
          allow(change_service).to receive(:change_contract_period!).and_raise(
            service_class::ScheduleNotFoundError
          )
        end

        it "adds a matching schedule error" do
          expect(step.save!).to be(false)
          expect(step.errors[:base]).to include("A matching schedule could not be found for the selected contract period")
        end
      end

      context "when the training period has no equivalent active lead provider" do
        before do
          allow(change_service).to receive(:change_contract_period!).and_raise(
            service_class::ActiveLeadProviderNotFoundError
          )
        end

        it "adds an active lead provider error" do
          expect(step.save!).to be(false)
          expect(step.errors[:base]).to include("An active lead provider could not be found for the selected contract period")
        end
      end
    end

    context "when using the current active period change service" do
      let(:service_class) { described_class::CurrentActivePeriodChange }
      let(:started_on) { today.prev_month }

      it_behaves_like "maps service errors to validation errors"
    end

    context "when using the future period change service" do
      let(:service_class) { described_class::FuturePeriodChange }

      it_behaves_like "maps service errors to validation errors"
    end
  end
end
