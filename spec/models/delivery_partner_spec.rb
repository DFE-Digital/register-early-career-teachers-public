describe DeliveryPartner do
  describe "associations" do
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:lead_provider_delivery_partnerships).inverse_of(:delivery_partner) }
    it { is_expected.to have_many(:school_partnerships).through(:lead_provider_delivery_partnerships) }
  end

  describe "validations" do
    subject { FactoryBot.build(:delivery_partner) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe "declarative touch" do
    let(:instance) { FactoryBot.create(:delivery_partner) }
    let(:target) { instance }

    it_behaves_like "a declarative touch model", when_changing: %i[name], timestamp_attribute: :api_updated_at
  end
end
