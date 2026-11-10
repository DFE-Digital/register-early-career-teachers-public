RSpec.describe Schools::AssignExistingMentorWizard::StateStore do
  subject(:state_store) { described_class.new }

  let(:school) { FactoryBot.create(:school, create_contract_period: false) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:mentor_teacher) { FactoryBot.create(:teacher, trs_first_name: "Goku", trs_last_name: "Saiyan") }
  let(:ect_teacher) { FactoryBot.create(:teacher, trs_first_name: "King", trs_last_name: "Vegeta") }
  let(:mentor_at_school_period) do
    FactoryBot.create(:mentor_at_school_period, :unfinished, school:, teacher: mentor_teacher)
  end
  let(:ect_at_school_period) do
    FactoryBot.create(:ect_at_school_period, :unfinished, school:, teacher: ect_teacher, started_on: 2.days.ago.to_date)
  end

  before do
    state_store.write(ect_id: ect_at_school_period.id, mentor_period_id: mentor_at_school_period.id)
  end

  describe "#started?" do
    it { is_expected.to be_started }

    it "is not started when only the mentor has been stored" do
      expect(described_class.new.tap { |store| store.write(mentor_period_id: 1) }).not_to be_started
    end

    it "is not started when nothing has been stored" do
      expect(described_class.new).not_to be_started
    end
  end

  describe "#ect_at_school_period" do
    it "returns the stored ECT at school period" do
      expect(state_store.ect_at_school_period).to eq(ect_at_school_period)
    end
  end

  describe "#mentor_at_school_period" do
    it "returns the stored mentor at school period" do
      expect(state_store.mentor_at_school_period).to eq(mentor_at_school_period)
    end
  end

  describe "#ect_teacher_full_name" do
    it "returns the ECTs full name" do
      expect(state_store.ect_teacher_full_name).to eq("King Vegeta")
    end
  end

  describe "#mentor_teacher_full_name" do
    it "returns the mentors full name" do
      expect(state_store.mentor_teacher_full_name).to eq("Goku Saiyan")
    end
  end

  describe "#ect_lead_provider" do
    let(:framework_agreement) { FactoryBot.create(:framework_agreement, lead_provider:) }

    context "when the ECT is training with a school partnership" do
      before do
        FactoryBot.create(
          :training_period,
          :provider_led,
          :unfinished,
          ect_at_school_period:,
          started_on: ect_at_school_period.started_on,
          school_partnership: FactoryBot.create(
            :school_partnership,
            school:,
            lead_provider_delivery_partnership: FactoryBot.create(:lead_provider_delivery_partnership, framework_agreement:)
          )
        )
      end

      it "returns the lead provider from the school partnership" do
        expect(state_store.ect_lead_provider).to eq(lead_provider)
      end
    end

    context "when the ECT is training via an expression of interest" do
      before do
        FactoryBot.create(
          :training_period,
          :provider_led,
          :unfinished,
          ect_at_school_period:,
          started_on: ect_at_school_period.started_on,
          school_partnership: nil,
          expression_of_interest: framework_agreement
        )
      end

      it "returns the lead provider from the expression of interest" do
        expect(state_store.ect_lead_provider).to eq(lead_provider)
      end
    end
  end

  describe "#ect_lead_provider_available?" do
    let!(:current_contract_period) { FactoryBot.create(:contract_period, :current) }
    let(:ect_lead_provider_contract_period) { current_contract_period }
    let(:framework_agreement) do
      FactoryBot.create(:framework_agreement, lead_provider:, contract_period: ect_lead_provider_contract_period)
    end
    let!(:ect_training_period) do
      FactoryBot.create(
        :training_period,
        :provider_led,
        :unfinished,
        :with_framework_agreement,
        ect_at_school_period:,
        started_on: ect_at_school_period.started_on,
        framework_agreement:
      )
    end

    context "when the ECTs lead provider has a framework agreement for the current contract period" do
      it { is_expected.to be_ect_lead_provider_available }
    end

    context "when the ECTs lead provider has no framework agreement for the current contract period" do
      let(:ect_lead_provider_contract_period) { FactoryBot.create(:contract_period, :previous) }

      it { is_expected.not_to be_ect_lead_provider_available }
    end

    context "when the ECT has no training period" do
      let!(:ect_training_period) { nil }

      it { is_expected.not_to be_ect_lead_provider_available }
    end
  end

  describe "#lead_providers_within_contract_period" do
    let!(:current_contract_period) { FactoryBot.create(:contract_period, :current) }
    let!(:earlier_contract_period) { FactoryBot.create(:contract_period, :previous) }
    let!(:lead_provider_1) { FactoryBot.create(:lead_provider) }
    let!(:lead_provider_2) { FactoryBot.create(:lead_provider) }
    let!(:excluded_provider) { FactoryBot.create(:lead_provider) }

    before do
      FactoryBot.create(:framework_agreement, contract_period: current_contract_period, lead_provider: lead_provider_1)
      FactoryBot.create(:framework_agreement, contract_period: current_contract_period, lead_provider: lead_provider_2)
      FactoryBot.create(:framework_agreement, contract_period: earlier_contract_period, lead_provider: excluded_provider)
    end

    it "returns only lead providers with a framework agreement for the current contract period" do
      expect(state_store.lead_providers_within_contract_period).to contain_exactly(lead_provider_1, lead_provider_2)
    end

    context "when the ECT started before the current contract period" do
      let(:ect_at_school_period) do
        FactoryBot.create(
          :ect_at_school_period,
          :unfinished,
          school:,
          teacher: ect_teacher,
          started_on: earlier_contract_period.started_on.next_month
        )
      end

      it "still returns the lead providers for the current contract period" do
        expect(state_store.lead_providers_within_contract_period).to contain_exactly(lead_provider_1, lead_provider_2)
      end
    end

    context "when there is no current contract period" do
      before { allow(ContractPeriod).to receive(:current).and_return(nil) }

      it "returns no lead providers" do
        expect(state_store.lead_providers_within_contract_period).to eq([])
      end
    end
  end
end
