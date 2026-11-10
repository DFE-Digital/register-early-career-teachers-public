RSpec.describe Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Operations::ApplyContractPeriodChange do
  subject(:operation) { described_class.new(repository: state_store.repository, step:) }

  let(:wizard) do
    Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Wizard.new(state_store:, current_step: :check_answers)
  end
  let(:step) { wizard.current_step }
  let(:state_store) do
    Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::StateStore.new(training_period:)
  end
  let(:today) { Date.new(2026, 2, 1) }
  let(:started_on) { today.next_month }
  let(:training_period) { FactoryBot.build_stubbed(:training_period, started_on:) }
  let(:selected_contract_period) { FactoryBot.build_stubbed(:contract_period, year: 2026) }
  let(:selected_school_partnership) { FactoryBot.build_stubbed(:school_partnership) }
  let(:author) { Events::SystemAuthor.new }
  let(:change_service) { instance_double(service_class, change_contract_period!: true) }

  before do
    allow(state_store).to receive_messages(selected_contract_period:, selected_school_partnership:)
    allow(wizard).to receive(:author).and_return(author)
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

  shared_examples "applies the change and maps service errors to validation errors" do
    it "changes the contract period" do
      expect(operation.execute).to eq(success: true)
      expect(change_service).to have_received(:change_contract_period!)
    end

    context "when the training period is not supported" do
      before do
        allow(change_service).to receive(:change_contract_period!).and_raise(
          Admin::Teachers::TrainingPeriods::ChangeContractPeriod::UnsupportedTrainingPeriodError
        )
      end

      it "adds an eligibility error" do
        expect(operation.execute).to include(success: false)
        expect(step.errors[:base]).to include("Training period is not eligible for contract period change")
      end
    end

    context "when the training period has no matching schedule" do
      before do
        allow(change_service).to receive(:change_contract_period!).and_raise(
          Admin::Teachers::TrainingPeriods::ChangeContractPeriod::ScheduleNotFoundError
        )
      end

      it "adds a matching schedule error" do
        expect(operation.execute).to include(success: false)
        expect(step.errors[:base]).to include("A matching schedule could not be found for the selected contract period")
      end
    end

    context "when the training period has no equivalent framework agreement" do
      before do
        allow(change_service).to receive(:change_contract_period!).and_raise(
          Admin::Teachers::TrainingPeriods::ChangeContractPeriod::FrameworkAgreementNotFoundError
        )
      end

      it "adds a framework agreement error" do
        expect(operation.execute).to include(success: false)
        expect(step.errors[:base]).to include("A lead provider framework agreement could not be found for the selected contract period")
      end
    end
  end

  context "when the training period has started" do
    let(:service_class) { Admin::Teachers::TrainingPeriods::ChangeContractPeriod::CurrentActivePeriod }
    let(:started_on) { today.prev_month }

    it_behaves_like "applies the change and maps service errors to validation errors"
  end

  context "when the training period starts in the future" do
    let(:service_class) { Admin::Teachers::TrainingPeriods::ChangeContractPeriod::FuturePeriod }

    it_behaves_like "applies the change and maps service errors to validation errors"
  end
end
