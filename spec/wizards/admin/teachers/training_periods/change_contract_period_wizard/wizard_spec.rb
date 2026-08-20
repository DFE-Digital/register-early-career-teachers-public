RSpec.describe Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Wizard do
  let(:today) { Date.new(2026, 2, 1) }
  let(:store) { FactoryBot.build(:session_repository) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:school) { FactoryBot.create(:school) }
  let(:current_contract_period) { FactoryBot.create(:contract_period, year: 2025) }
  let(:target_contract_period) { FactoryBot.create(:contract_period, year: 2026) }
  let(:other_contract_period) { FactoryBot.create(:contract_period, year: 2027) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
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
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :unfinished, teacher:, school:) }
  let(:schedule) { FactoryBot.create(:schedule, contract_period: current_contract_period) }
  let(:training_period) do
    FactoryBot.create(
      :training_period,
      :unfinished,
      ect_at_school_period:,
      school_partnership:,
      schedule:
    )
  end
  let(:current_step) { :select_contract_period }
  let(:wizard) do
    described_class.new(
      store:,
      teacher_id: teacher.id,
      training_period_id: training_period.id,
      current_step:
    )
  end

  around do |example|
    travel_to(today) { example.run }
  end

  describe "#allowed_steps" do
    subject { wizard.allowed_steps }

    context "when no contract period has been selected" do
      it { is_expected.to eq([:select_contract_period]) }
    end

    context "when an available contract period has been selected" do
      before { store.contract_period_year = target_contract_period.year }

      it { is_expected.to eq(%i[select_contract_period check_answers]) }

      context "when there are multiple partnerships for the school and contract period" do
        before do
          FactoryBot.create(:school_partnership, :for_year, year: target_contract_period.year, school:)
        end

        it { is_expected.to eq(%i[select_contract_period select_partnership]) }
      end
    end

    context "when an available contract period has no partnerships for the school" do
      let(:target_school_partnership) { nil }

      before { store.contract_period_year = target_contract_period.year }

      it { is_expected.to eq(%i[select_contract_period no_partnerships]) }
    end

    context "when an available contract period and partnership have been selected" do
      before do
        FactoryBot.create(:school_partnership, :for_year, year: target_contract_period.year, school:)
        store.contract_period_year = target_contract_period.year
        store.school_partnership_id = target_school_partnership.id
      end

      it { is_expected.to eq(%i[select_contract_period select_partnership check_answers]) }
    end

    context "when an EOI only period has a valid contract period selection" do
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

      before do
        FactoryBot.create(:framework_agreement, lead_provider: framework_agreement.lead_provider, contract_period: target_contract_period)
        store.contract_period_year = target_contract_period.year
      end

      it { is_expected.to eq(%i[select_contract_period check_answers]) }
    end

    context "when an unavailable contract period has been selected" do
      before { store.contract_period_year = current_contract_period.year }

      it { is_expected.to eq([:select_contract_period]) }
    end

    context "when an unavailable partnership has been selected" do
      before do
        FactoryBot.create(:school_partnership, :for_year, year: target_contract_period.year, school:)
        store.contract_period_year = target_contract_period.year
        store.school_partnership_id = school_partnership.id
      end

      it { is_expected.to eq(%i[select_contract_period select_partnership]) }
    end
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
        .and_return(available_contract_periods)

      expect(wizard.contract_periods).to eq(contract_periods)
      expect(Admin::Teachers::TrainingPeriods::ChangeContractPeriod::AvailableContractPeriods)
        .to have_received(:new)
        .with(training_period: wizard.training_period)
    end
  end

  describe "#selected_school_partnership" do
    before { store.contract_period_year = target_contract_period.year }

    it "infers the selected partnership when there is only one available partnership" do
      expect(wizard.selected_school_partnership).to eq(target_school_partnership)
    end

    context "when there are multiple partnerships" do
      before do
        FactoryBot.create(:school_partnership, :for_year, year: target_contract_period.year, school:)
      end

      it "returns nil without a stored partnership selection" do
        expect(wizard.selected_school_partnership).to be_nil
      end
    end
  end

  describe "#school_partnerships" do
    let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Target lead provider") }
    let(:delivery_partner) { FactoryBot.create(:delivery_partner, name: "Target delivery partner") }
    let!(:different_school_partnership) do
      FactoryBot.create(
        :school_partnership,
        :for_year,
        year: target_contract_period.year,
        school:
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

    before do
      FactoryBot.create(:school_partnership, :for_year, year: target_contract_period.year)
      FactoryBot.create(:school_partnership, :for_year, year: other_contract_period.year, school:)
    end

    context "when no contract period has been selected" do
      it "returns no school partnerships" do
        expect(wizard.school_partnerships).to be_empty
      end
    end

    context "when a contract period has been selected" do
      before { store.contract_period_year = target_contract_period.year }

      it "returns school partnerships for the selected contract period and school" do
        expect(wizard.school_partnerships).to contain_exactly(target_school_partnership, different_school_partnership)
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
          expect(wizard.school_partnerships).to contain_exactly(target_school_partnership)
        end

        context "when the future period has a different LP/DP from the current active period" do
          let(:current_school_partnership) do
            FactoryBot.create(
              :school_partnership,
              :for_year,
              year: current_contract_period.year,
              school:
            )
          end

          it "returns no school partnerships" do
            expect(wizard.school_partnerships).to be_empty
          end
        end
      end
    end
  end

  describe "#partnership_options" do
    let(:lead_provider) { FactoryBot.create(:lead_provider, name: "Target lead provider") }
    let(:delivery_partner) { FactoryBot.create(:delivery_partner, name: "Target delivery partner") }
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

    before do
      store.contract_period_year = target_contract_period.year
    end

    it "returns options for the available partnerships" do
      expect(wizard.partnership_options).to contain_exactly(
        have_attributes(
          id: target_school_partnership.id,
          name: "Target lead provider & Target delivery partner"
        )
      )
    end
  end
end
