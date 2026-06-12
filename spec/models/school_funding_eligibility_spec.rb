RSpec.describe SchoolFundingEligibility do
  describe "associations" do
    it { is_expected.to belong_to(:gias_school).class_name("GIAS::School").with_foreign_key(:school_urn).with_primary_key(:urn).inverse_of(:school_funding_eligibilities) }
    it { is_expected.to belong_to(:contract_period).with_foreign_key(:contract_period_year).with_primary_key(:year) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:gias_school) }
    it { is_expected.to validate_presence_of(:contract_period) }
    it { is_expected.to allow_values(true, false).for(:pupil_premium_uplift) }
    it { is_expected.not_to allow_values(nil, "").for(:pupil_premium_uplift) }
    it { is_expected.to allow_values(true, false).for(:sparsity_uplift) }
    it { is_expected.not_to allow_values(nil, "").for(:sparsity_uplift) }
  end

  describe "GIAS school foreign key" do
    it "allows funding eligibility for a GIAS school that is not a service school" do
      gias_school = FactoryBot.create(:gias_school)
      contract_period = FactoryBot.create(:contract_period)

      eligibility = FactoryBot.create(:school_funding_eligibility, gias_school:, contract_period:)

      expect(eligibility.reload.gias_school).to eq(gias_school)
      expect(School.exists?(urn: gias_school.urn)).to be(false)
    end

    it "resolves a service school's current GIAS school's eligibility after a URN swap" do
      old_gias_school = FactoryBot.create(:gias_school)
      new_gias_school = FactoryBot.create(:gias_school)
      contract_period = FactoryBot.create(:contract_period)
      school = FactoryBot.create(:school, gias_school: old_gias_school, urn: old_gias_school.urn)
      old_eligibility = FactoryBot.create(:school_funding_eligibility, gias_school: old_gias_school, contract_period:)
      new_eligibility = FactoryBot.create(:school_funding_eligibility, gias_school: new_gias_school, contract_period:)

      school.update!(urn: new_gias_school.urn)

      expect(school.reload.school_funding_eligibilities).to contain_exactly(new_eligibility)
      expect(old_gias_school.school_funding_eligibilities).to contain_exactly(old_eligibility)
    end
  end
end
