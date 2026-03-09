RSpec.describe SchoolFundingEligibility do
  describe "associations" do
    it { is_expected.to belong_to(:school).with_foreign_key(:school_urn).with_primary_key(:urn) }
    it { is_expected.to belong_to(:contract_period).with_foreign_key(:contract_period_year).with_primary_key(:year) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:school) }
    it { is_expected.to validate_presence_of(:contract_period) }
    it { is_expected.to allow_values(true, false).for(:pupil_premium_uplift) }
    it { is_expected.not_to allow_values(nil, "").for(:pupil_premium_uplift) }
    it { is_expected.to allow_values(true, false).for(:sparsity_uplift) }
    it { is_expected.not_to allow_values(nil, "").for(:sparsity_uplift) }
  end

  describe "declarative touch" do
    describe "school target" do
      let(:instance) { FactoryBot.create(:school_funding_eligibility, school: target) }
      let!(:target) { FactoryBot.create(:school) }

      it_behaves_like "a declarative metadata model", on_event: %i[create destroy update]
    end
  end
end
