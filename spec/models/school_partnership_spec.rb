describe SchoolPartnership do
  describe "associations" do
    it { is_expected.to belong_to(:lead_provider_delivery_partnership).optional }
    it { is_expected.to belong_to(:school) }
    it { is_expected.to have_many(:training_periods).inverse_of(:confirmed_school_partnership) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:school) }
  end
end
