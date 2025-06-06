describe SchoolPartnership do
  describe "associations" do
    it { is_expected.to belong_to(:delivery_partner).inverse_of(:school_partnerships) }
    it { is_expected.to belong_to(:available_provider_pairing).inverse_of(:school_partnerships) }
    it { is_expected.to have_many(:events) }
  end

  describe "validations" do
    subject { FactoryBot.create(:school_partnership) }

    it { is_expected.to validate_presence_of(:delivery_partner_id) }
    it { is_expected.to validate_presence_of(:available_provider_pairing_id) }
  end
end
