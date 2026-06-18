RSpec.describe Admin::Teachers::TrainingPeriods::ChangeContractPeriodWizard::Wizard do
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
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:) }
  let(:schedule) { FactoryBot.create(:schedule, contract_period: current_contract_period) }
  let(:training_period) do
    FactoryBot.create(
      :training_period,
      :ongoing,
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

  describe "#allowed_steps" do
    subject { wizard.allowed_steps }

    context "when no contract period has been selected" do
      it { is_expected.to eq([:select_contract_period]) }
    end

    context "when an available contract period has been selected" do
      before { store.contract_period_year = target_contract_period.year }

      it { is_expected.to eq(%i[select_contract_period select_partnership]) }
    end

    context "when an available contract period has no partnerships for the current lead provider and delivery partner" do
      let(:target_school_partnership) { nil }

      before { store.contract_period_year = target_contract_period.year }

      it { is_expected.to eq(%i[select_contract_period no_partnerships]) }
    end

    context "when an available contract period and partnership have been selected" do
      before do
        store.contract_period_year = target_contract_period.year
        store.school_partnership_id = target_school_partnership.id
      end

      it { is_expected.to eq(%i[select_contract_period select_partnership check_answers]) }
    end

    context "when an unavailable contract period has been selected" do
      before { store.contract_period_year = current_contract_period.year }

      it { is_expected.to eq([:select_contract_period]) }
    end

    context "when an unavailable partnership has been selected" do
      before do
        store.contract_period_year = target_contract_period.year
        store.school_partnership_id = school_partnership.id
      end

      it { is_expected.to eq(%i[select_contract_period select_partnership]) }
    end
  end

  describe "#contract_periods" do
    let!(:contract_period_2021) { FactoryBot.create(:contract_period, year: 2021) }
    let!(:contract_period_2022) { FactoryBot.create(:contract_period, year: 2022) }
    let!(:disabled_contract_period) { FactoryBot.create(:contract_period, year: 2028, enabled: false) }

    it "returns enabled contract periods excluding the current and frozen years" do
      expect(wizard.contract_periods).to contain_exactly(target_contract_period, other_contract_period)
    end

    context "when the original frozen contract period is 2021" do
      before do
        teacher.update!(ect_payments_frozen_year: contract_period_2021.year)
      end

      it "keeps the original frozen contract period" do
        expect(wizard.contract_periods)
          .to contain_exactly(contract_period_2021, target_contract_period, other_contract_period)
      end
    end

    context "when the original frozen contract period is 2022" do
      before do
        teacher.update!(ect_payments_frozen_year: contract_period_2022.year)
      end

      it "keeps the original frozen contract period" do
        expect(wizard.contract_periods)
          .to contain_exactly(contract_period_2022, target_contract_period, other_contract_period)
      end
    end
  end

  describe "#school_partnerships" do
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

      it "returns school partnerships for the selected contract period, school, lead provider and delivery partner" do
        expect(wizard.school_partnerships).to contain_exactly(target_school_partnership)
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
