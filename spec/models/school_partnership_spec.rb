describe SchoolPartnership do
  describe "associations" do
    it { is_expected.to belong_to(:lead_provider_delivery_partnership).inverse_of(:school_partnerships) }
    it { is_expected.to belong_to(:school) }
    it { is_expected.to have_many(:events) }
  end

  describe "validations" do
    subject { create(:school_partnership) }

    it { is_expected.to validate_presence_of(:lead_provider_delivery_partnership_id) }
    it { is_expected.to validate_presence_of(:school_id) }
    it { is_expected.to validate_uniqueness_of(:school_id).scoped_to(:lead_provider_delivery_partnership_id).with_message('School and lead provider delivery partnership combination must be unique') }
  end

  describe 'scopes' do
    describe '.earliest_first' do
      let!(:school_partnership_first) { create(:school_partnership, created_at: 3.weeks.ago) }
      let!(:school_partnership_second) { create(:school_partnership, created_at: 2.weeks.ago) }
      let!(:school_partnership_third) { create(:school_partnership, created_at: 1.week.ago) }

      it 'orders with earliest created records first' do
        expect(SchoolPartnership.earliest_first).to eq([
          school_partnership_first,
          school_partnership_second,
          school_partnership_third,
        ])
      end
    end
  end
end
