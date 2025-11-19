RSpec.describe Schools::Shared::MentorAssignmentContext do
  subject(:context) do
    described_class.new(
      store:,
      mentor_at_school_period:,
      ect_at_school_period:
    )
  end

  let(:school) { FactoryBot.create(:school) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:store) { FactoryBot.build(:session_repository, lead_provider_id: lead_provider.id) }

  let(:mentor_teacher) { FactoryBot.create(:teacher, trn: "1234567", trs_first_name: "Goku", trs_last_name: "Saiyan", mentor_became_ineligible_for_funding_reason: nil) }
  let(:ect_teacher) { FactoryBot.create(:teacher, trs_first_name: "King", trs_last_name: "Vegeta") }

  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:, teacher: mentor_teacher) }
  let(:ect_at_school_period) do
    FactoryBot.create(:ect_at_school_period, school:, teacher: ect_teacher, started_on: Date.new(2025, 5, 1))
  end

  describe "#ect_teacher_full_name" do
    it "returns the ECTs full name" do
      expect(context.ect_teacher_full_name).to eq("King Vegeta")
    end
  end

  describe "#mentor_teacher_full_name" do
    it "returns the mentors full name" do
      expect(context.mentor_teacher_full_name).to eq("Goku Saiyan")
    end
  end

  describe "#already_active_at_school" do
    it "returns true when both ECT and mentor are at the same school" do
      expect(context.already_active_at_school?).to be(true)
    end
  end

  describe "#eligible_for_funding?" do
    it "returns true if mentor_became_ineligible_for_funding_reason is nil" do
      expect(context.eligible_for_funding?).to be(true)
    end
  end

  describe "#user_selected_lead_provider" do
    it "returns the lead provider from the store" do
      expect(context.user_selected_lead_provider).to eq(lead_provider)
    end
  end

  describe "#ect_lead_provider" do
    let(:started_on) { 2.days.ago.to_date }
    let(:finished_on) { 2.days.from_now.to_date }

    let(:school_partnership) do
      active_lp = FactoryBot.create(:active_lead_provider, lead_provider:)
      lpdp = FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: active_lp)
      FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership: lpdp)
    end

    let(:ect_at_school_period) do
      FactoryBot.create(:ect_at_school_period, started_on:, finished_on:, school:, teacher: ect_teacher)
    end

    let!(:training_period) do
      FactoryBot.create(
        :training_period,
        :provider_led,
        :ongoing,
        ect_at_school_period:,
        started_on:,
        finished_on:,
        school_partnership:
      )
    end

    it "returns the ECT lead provider using CurrentTraining service" do
      expect(context.ect_lead_provider).to eq(lead_provider)
    end
  end

  describe "#lead_providers_within_contract_period" do
    let!(:in_contract_period) do
      FactoryBot.create(:contract_period, started_on: Date.new(2025, 1, 1), finished_on: Date.new(2025, 12, 31))
    end

    let!(:out_of_contract_period) do
      FactoryBot.create(:contract_period, started_on: Date.new(2024, 1, 1), finished_on: Date.new(2024, 12, 31))
    end

    let!(:lead_provider_1) { FactoryBot.create(:lead_provider) }
    let!(:lead_provider_2) { FactoryBot.create(:lead_provider) }
    let!(:excluded_provider) { FactoryBot.create(:lead_provider) }

    before do
      FactoryBot.create(:active_lead_provider, contract_period: in_contract_period, lead_provider: lead_provider_1)
      FactoryBot.create(:active_lead_provider, contract_period: in_contract_period, lead_provider: lead_provider_2)
      FactoryBot.create(:active_lead_provider, contract_period: out_of_contract_period, lead_provider: excluded_provider)
    end

    it "returns only lead providers within the ECTs contract period" do
      expect(context.lead_providers_within_contract_period).to contain_exactly(lead_provider_1, lead_provider_2)
    end
  end
end
