describe Migration::InductionRecord, type: :model do
  describe "associations" do
    it { is_expected.to have_one(:school_cohort).through(:induction_programme) }
    it { is_expected.to have_one(:school).through(:school_cohort) }
    it { is_expected.to have_one(:partnership).through(:induction_programme) }
    it { is_expected.to have_one(:delivery_partner).through(:partnership) }
    it { is_expected.to have_one(:lead_provider).through(:partnership) }
  end
end
