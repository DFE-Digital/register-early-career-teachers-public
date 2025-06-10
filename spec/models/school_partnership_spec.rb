describe SchoolPartnership do
  describe "associations" do
    it { is_expected.to belong_to(:registration_period).inverse_of(:school_partnerships) }
    it { is_expected.to belong_to(:lead_provider).inverse_of(:school_partnerships) }
    it { is_expected.to belong_to(:delivery_partner).inverse_of(:school_partnerships) }
    it { is_expected.to have_many(:events) }
  end

  describe "validations" do
    subject { FactoryBot.create(:school_partnership) }

    it { is_expected.to validate_presence_of(:lead_provider_delivery_partnership_id) }
  end
end
