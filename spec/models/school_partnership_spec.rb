describe SchoolPartnership do
  describe "associations" do
    it { is_expected.to belong_to(:lead_provider_delivery_partnership).optional }
    it { is_expected.to belong_to(:school) }
    it { is_expected.to have_many(:training_periods).inverse_of(:confirmed_school_partnership) }
  end

  describe "validations" do
    subject { build(:school_partnership) }

    it { is_expected.to validate_presence_of(:school) }
    it { expect(subject).to validate_uniqueness_of(:school_id).scoped_to(:lead_provider_delivery_partnership_id) }
  end
end
