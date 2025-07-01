describe SchoolPartnerships::Query do
  let!(:lead_provider) { FactoryBot.create(:lead_provider) }
  let!(:registration_period) { FactoryBot.create(:registration_period, year: 2027) }
  let!(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let!(:school) { FactoryBot.create(:school) }

  let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, registration_period:) }
  let!(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
  let!(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:, school:) }

  let(:query_params) { { lead_provider:, school:, delivery_partner:, registration_period: } }

  describe '#exists?' do
    it 'returns true when a school partnership matches lead provider, delivery partner and school for the given registration period' do
      expect(SchoolPartnerships::Query.new(lead_provider:, school:, registration_period:)).to exist
    end

    describe 'registration periods' do
      context 'when registration_period differs' do
        subject { SchoolPartnerships::Query.new(**query_params.merge(registration_period: other_registration_period)) }

        let(:other_registration_period) { FactoryBot.create(:registration_period, year: 2028) }

        it { is_expected.not_to(exist) }
      end

      context 'when registration_period omitted' do
        subject { SchoolPartnerships::Query.new(**query_params.except(:registration_period)) }

        it { is_expected.to(exist) }
      end
    end

    describe 'lead providers' do
      context 'when lead_provider differs' do
        subject { SchoolPartnerships::Query.new(**query_params.merge(lead_provider: other_lead_provider)) }

        let(:other_lead_provider) { FactoryBot.create(:lead_provider) }

        it { is_expected.not_to(exist) }
      end

      context 'when lead_provider omitted' do
        subject { SchoolPartnerships::Query.new(**query_params.except(:lead_provider)) }

        it { is_expected.to(exist) }
      end
    end

    describe 'schools' do
      context 'when school differs' do
        subject { SchoolPartnerships::Query.new(**query_params.merge(school: other_school)) }

        let(:other_school) { FactoryBot.create(:school) }

        it { is_expected.not_to(exist) }
      end

      context 'when school omitted' do
        subject { SchoolPartnerships::Query.new(**query_params.except(:school)) }

        it { is_expected.to(exist) }
      end
    end

    describe 'delivery partners' do
      context 'when delivery partner differs' do
        subject { SchoolPartnerships::Query.new(**query_params.merge(delivery_partner: other_delivery_partner)) }

        let(:other_delivery_partner) { FactoryBot.create(:delivery_partner) }

        it { is_expected.not_to(exist) }
      end

      context 'when delivery_partner omitted' do
        subject { SchoolPartnerships::Query.new(**query_params.except(:delivery_partner)) }

        it { is_expected.to(exist) }
      end
    end
  end
end
