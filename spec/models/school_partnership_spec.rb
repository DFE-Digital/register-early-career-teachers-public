describe SchoolPartnership do
  describe "associations" do
    it { is_expected.to belong_to(:lead_provider_delivery_partnership).inverse_of(:school_partnerships) }
    it { is_expected.to have_many(:events) }
  end

  describe "validations" do
    subject { FactoryBot.create(:school_partnership) }

    it { is_expected.to validate_presence_of(:lead_provider_delivery_partnership_id) }
  end
end
