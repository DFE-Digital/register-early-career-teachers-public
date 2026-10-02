RSpec.describe Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Wizard do
  subject(:wizard) { described_class.new(state_store:, current_step:) }

  let(:state_store) do
    Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::StateStore.new(training_period:)
  end
  let(:current_step) { :select_contract_period }
  let(:today) { Date.new(2026, 2, 1) }
  let(:school) { FactoryBot.create(:school) }
  let(:current_contract_period) { FactoryBot.create(:contract_period, year: 2025) }
  let(:target_contract_period) { FactoryBot.create(:contract_period, year: 2026) }
  let(:school_partnership) do
    FactoryBot.create(:school_partnership, :for_year, year: current_contract_period.year, school:)
  end
  let!(:target_school_partnership) do
    FactoryBot.create(:school_partnership, :for_year, year: target_contract_period.year, school:)
  end
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :unfinished, school:) }
  let(:schedule) { FactoryBot.create(:schedule, contract_period: current_contract_period) }
  let(:training_period) do
    FactoryBot.create(:training_period, :unfinished, ect_at_school_period:, school_partnership:, schedule:)
  end

  around do |example|
    travel_to(today) { example.run }
  end

  def path_for(step)
    Rails.application.routes.url_helpers.public_send(
      "admin_teacher_training_period_change_contract_period_wizard_#{step}_path",
      training_period.teacher_id,
      training_period.id
    )
  end

  def create_another_target_school_partnership
    FactoryBot.create(:school_partnership, :for_year, year: target_contract_period.year, school:)
  end

  it { is_expected.to have_root_step(:select_contract_period) }

  it "defines a route for every step" do
    expect(described_class.routes).to match_array(wizard.step_definitions.keys)
  end

  it "resolves step paths for the training period" do
    expect(wizard).to resolve_step(:check_answers).to(path_for(:check_answers))
  end

  describe "operations" do
    it "resets the partnership selection when a contract period is selected" do
      expect(wizard).to have_step_operations(
        select_contract_period: [
          DfE::Wizard::Operations::Validate,
          DfE::Wizard::Operations::Persist,
          Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Operations::ResetSchoolPartnershipSelection
        ]
      )
    end

    it "only applies the change on check answers" do
      expect(wizard).to have_step_operations(
        check_answers: [Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Operations::ApplyContractPeriodChange]
      )
    end
  end

  describe "navigation" do
    it "goes to check answers when there is only one partnership" do
      expect(wizard).to branch_from(:select_contract_period)
        .to(:check_answers)
        .when(contract_period_year: target_contract_period.year)
    end

    it "goes to select partnership when there are multiple partnerships" do
      create_another_target_school_partnership

      expect(wizard).to branch_from(:select_contract_period)
        .to(:select_partnership)
        .when(contract_period_year: target_contract_period.year)
    end

    context "when there are no partnerships" do
      let(:target_school_partnership) { nil }

      it "goes to no partnerships" do
        expect(wizard).to branch_from(:select_contract_period)
          .to(:no_partnerships)
          .when(contract_period_year: target_contract_period.year)
      end

      it { is_expected.to have_previous_step(:select_contract_period).from(:no_partnerships) }
    end

    context "when the training period only has an expression of interest" do
      let(:target_school_partnership) { nil }
      let(:framework_agreement) { FactoryBot.create(:framework_agreement, contract_period: current_contract_period) }
      let(:training_period) do
        FactoryBot.create(
          :training_period,
          :unfinished,
          :with_only_expression_of_interest,
          ect_at_school_period:,
          expression_of_interest: framework_agreement,
          schedule:
        )
      end

      it "goes to check answers" do
        expect(wizard).to branch_from(:select_contract_period)
          .to(:check_answers)
          .when(contract_period_year: target_contract_period.year)
      end
    end

    it { is_expected.to have_next_step(:check_answers).from(:select_partnership) }

    it "goes back from check answers to select contract period when there is only one partnership" do
      expect(wizard).to have_previous_step(:select_contract_period)
        .from(:check_answers)
        .when(contract_period_year: target_contract_period.year)
    end

    it "goes back from check answers to select partnership when there are multiple partnerships" do
      create_another_target_school_partnership

      expect(wizard).to have_previous_step(:select_partnership)
        .from(:check_answers)
        .when(contract_period_year: target_contract_period.year)
    end
  end

  describe "#furthest_valid_step_path" do
    subject { wizard.furthest_valid_step_path }

    context "when no contract period has been selected" do
      it { is_expected.to eq(path_for(:select_contract_period)) }
    end

    context "when an unavailable contract period has been selected" do
      before { state_store.write(contract_period_year: current_contract_period.year) }

      it { is_expected.to eq(path_for(:select_contract_period)) }
    end

    context "when an available contract period with one partnership has been selected" do
      before { state_store.write(contract_period_year: target_contract_period.year) }

      it { is_expected.to eq(path_for(:check_answers)) }
    end

    context "when an available contract period with no partnerships has been selected" do
      let(:target_school_partnership) { nil }

      before { state_store.write(contract_period_year: target_contract_period.year) }

      it { is_expected.to eq(path_for(:no_partnerships)) }
    end

    context "when there are multiple partnerships" do
      before do
        create_another_target_school_partnership
        state_store.write(contract_period_year: target_contract_period.year, school_partnership_id:)
      end

      context "when no partnership has been selected" do
        let(:school_partnership_id) { nil }

        it { is_expected.to eq(path_for(:select_partnership)) }
      end

      context "when an unavailable partnership has been selected" do
        let(:school_partnership_id) { school_partnership.id }

        it { is_expected.to eq(path_for(:select_partnership)) }
      end

      context "when an available partnership has been selected" do
        let(:school_partnership_id) { target_school_partnership.id }

        it { is_expected.to eq(path_for(:check_answers)) }
      end
    end
  end

  describe "#valid_path_to?" do
    it "is invalid before a contract period has been selected" do
      expect(wizard).not_to be_valid_to(:check_answers)
    end

    it "is valid once an available contract period has been selected" do
      state_store.write(contract_period_year: target_contract_period.year)

      expect(wizard).to be_valid_to(:check_answers)
    end
  end
end
