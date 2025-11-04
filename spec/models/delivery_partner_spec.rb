describe DeliveryPartner do
  describe "declarative updates" do
    let(:instance) { FactoryBot.create(:delivery_partner) }
    let(:target) { instance }

    it_behaves_like "a declarative metadata model", on_event: %i[create]
  end

  describe "associations" do
    it { is_expected.to have_many(:events) }
    it { is_expected.to have_many(:lead_provider_delivery_partnerships).inverse_of(:delivery_partner) }
    it { is_expected.to have_many(:school_partnerships).through(:lead_provider_delivery_partnerships) }
    it { is_expected.to have_many(:lead_provider_metadata).class_name("Metadata::DeliveryPartnerLeadProvider") }
    it { is_expected.to have_many(:training_periods).through(:school_partnerships) }
    it { is_expected.to have_many(:ect_at_school_periods).through(:training_periods) }
    it { is_expected.to have_many(:mentor_at_school_periods).through(:training_periods) }
    it { is_expected.to have_many(:ect_teachers).through(:ect_at_school_periods).source(:teacher) }
    it { is_expected.to have_many(:mentor_teachers).through(:mentor_at_school_periods).source(:teacher) }
  end

  describe "validations" do
    subject { FactoryBot.build(:delivery_partner) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive.with_message("A delivery partner with this name already exists") }
    it { is_expected.to validate_uniqueness_of(:api_id).case_insensitive.with_message("API id already exists for another delivery partner") }
  end

  describe "normalizing" do
    subject { FactoryBot.build(:delivery_partner, name: " Some delivery partner ") }

    it "removes leading and trailing spaces from the name" do
      expect(subject.name).to eql("Some delivery partner")
    end
  end

  describe "declarative touch" do
    let(:instance) { FactoryBot.create(:delivery_partner) }

    context "target delivery_partner" do
      let(:target) { instance }

      it_behaves_like "a declarative touch model", when_changing: %i[name], timestamp_attribute: :api_updated_at
    end

    context "target school_partnerships" do
      let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner: instance) }
      let!(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:) }
      let(:target) { school_partnership }

      it_behaves_like "a declarative touch model", when_changing: %i[name], timestamp_attribute: :api_updated_at
    end

    context "target ect_teachers" do
      let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner: instance) }
      let(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:) }
      let!(:training_period) { FactoryBot.create(:training_period, :for_ect, :ongoing, school_partnership:) }

      let(:target) { instance.ect_teachers }

      it_behaves_like "a declarative touch model", when_changing: %i[api_id], timestamp_attribute: :api_updated_at
    end

    context "target mentor_teachers" do
      let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner: instance) }
      let(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:) }
      let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, :ongoing, school_partnership:) }

      let(:target) { instance.mentor_teachers }

      it_behaves_like "a declarative touch model", when_changing: %i[api_id], timestamp_attribute: :api_updated_at
    end
  end
end
