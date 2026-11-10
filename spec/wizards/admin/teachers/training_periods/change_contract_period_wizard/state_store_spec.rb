RSpec.describe Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::StateStore do
  subject(:state_store) { described_class.new(training_period:) }

  let(:today) { Date.new(2026, 2, 1) }
  let(:school) { FactoryBot.create(:school) }
  let(:current_contract_period) { FactoryBot.create(:contract_period, year: 2025) }
  let(:target_contract_period) { FactoryBot.create(:contract_period, year: 2026) }
  let(:other_contract_period) { FactoryBot.create(:contract_period, year: 2027) }
  let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Target lead provider") }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner, name: "Target delivery partner") }
  let(:school_partnership) do
    FactoryBot.create(
      :school_partnership,
      :for_year,
      year: current_contract_period.year,
      school:,
      lead_provider:,
      delivery_partner:
    )
  end
  let!(:target_school_partnership) do
    FactoryBot.create(
      :school_partnership,
      :for_year,
      year: target_contract_period.year,
      school:,
      lead_provider:,
      delivery_partner:
    )
  end
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :unfinished, school:) }
  let(:schedule) { FactoryBot.create(:schedule, contract_period: current_contract_period) }
  let(:training_period) do
    FactoryBot.create(:training_period, :unfinished, ect_at_school_period:, school_partnership:, schedule:)
  end

  around do |example|
    travel_to(today) { example.run }
  end

  before do
    Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Wizard.new(state_store:)
  end

  describe "#contract_periods" do
    let(:contract_periods) { [target_contract_period] }
    let(:available_contract_periods) do
      instance_double(
        Admin::Teachers::TrainingPeriods::ChangeContractPeriod::AvailableContractPeriods,
        contract_periods:
      )
    end

    it "delegates to AvailableContractPeriods" do
      allow(Admin::Teachers::TrainingPeriods::ChangeContractPeriod::AvailableContractPeriods)
        .to receive(:new)
        .with(training_period:)
        .and_return(available_contract_periods)

      expect(state_store.contract_periods).to eq(contract_periods)
    end
  end

  describe "#selected_contract_period" do
    it "is nil without a stored selection" do
      expect(state_store.selected_contract_period).to be_nil
    end

    it "returns the selected available contract period" do
      state_store.write(contract_period_year: target_contract_period.year)

      expect(state_store.selected_contract_period).to eq(target_contract_period)
    end

    it "is nil when the selected contract period is not available" do
      state_store.write(contract_period_year: current_contract_period.year)

      expect(state_store.selected_contract_period).to be_nil
    end
  end

  describe "#selected_school_partnership" do
    before { state_store.write(contract_period_year: target_contract_period.year) }

    it "infers the selected partnership when there is only one available partnership" do
      expect(state_store.selected_school_partnership).to eq(target_school_partnership)
    end

    context "when there are multiple partnerships" do
      let!(:different_school_partnership) do
        FactoryBot.create(:school_partnership, :for_year, year: target_contract_period.year, school:)
      end

      it "returns nil without a stored partnership selection" do
        expect(state_store.selected_school_partnership).to be_nil
      end

      it "returns the stored partnership selection" do
        state_store.write(school_partnership_id: different_school_partnership.id)

        expect(state_store.selected_school_partnership).to eq(different_school_partnership)
      end
    end
  end

  describe "#school_partnerships" do
    let!(:different_school_partnership) do
      FactoryBot.create(:school_partnership, :for_year, year: target_contract_period.year, school:)
    end

    before do
      FactoryBot.create(:school_partnership, :for_year, year: target_contract_period.year)
      FactoryBot.create(:school_partnership, :for_year, year: other_contract_period.year, school:)
    end

    context "when no contract period has been selected" do
      it "returns no school partnerships" do
        expect(state_store.school_partnerships).to be_empty
      end
    end

    context "when a contract period has been selected" do
      before { state_store.write(contract_period_year: target_contract_period.year) }

      it "returns school partnerships for the selected contract period and school" do
        expect(state_store.school_partnerships).to contain_exactly(target_school_partnership, different_school_partnership)
      end

      context "when the selected training period starts in the future and has a current active period" do
        let(:future_started_on) { today.next_month }
        let(:current_school_partnership) { school_partnership }
        let!(:current_training_period) do
          FactoryBot.create(
            :training_period,
            :provider_led,
            ect_at_school_period:,
            school_partnership: current_school_partnership,
            schedule:,
            started_on: today.prev_month,
            finished_on: future_started_on.yesterday
          )
        end
        let(:training_period) do
          FactoryBot.create(
            :training_period,
            :provider_led,
            ect_at_school_period:,
            school_partnership:,
            schedule:,
            started_on: future_started_on
          )
        end

        it "returns school partnerships for the selected contract period, school and current active LP/DP" do
          expect(state_store.school_partnerships).to contain_exactly(target_school_partnership)
        end

        context "when the future period has a different LP/DP from the current active period" do
          let(:current_school_partnership) do
            FactoryBot.create(:school_partnership, :for_year, year: current_contract_period.year, school:)
          end

          it "returns no school partnerships" do
            expect(state_store.school_partnerships).to be_empty
          end
        end
      end
    end
  end

  describe "#partnership_options" do
    before { state_store.write(contract_period_year: target_contract_period.year) }

    it "returns options for the available partnerships" do
      expect(state_store.partnership_options).to contain_exactly(
        have_attributes(
          id: target_school_partnership.id,
          name: "Target lead provider & Target delivery partner"
        )
      )
    end
  end

  describe "#selected_partnership_name" do
    before { state_store.write(contract_period_year: target_contract_period.year) }

    it "names the lead provider and delivery partner of the selected partnership" do
      expect(state_store.selected_partnership_name).to eq("Target lead provider & Target delivery partner")
    end
  end

  describe "#existing_contract_period" do
    it "returns the contract period of the training period" do
      expect(state_store.existing_contract_period).to eq(current_contract_period)
    end
  end
end
