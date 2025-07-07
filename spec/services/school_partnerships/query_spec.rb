describe SchoolPartnerships::Query do
  let!(:lead_provider) { create(:lead_provider) }
  let!(:contract_period) { create(:contract_period, year: 2027) }
  let!(:delivery_partner) { create(:delivery_partner) }
  let!(:school) { create(:school) }

  let!(:active_lead_provider) { create(:active_lead_provider, lead_provider:, contract_period:) }
  let!(:lead_provider_delivery_partnership) { create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
  let!(:school_partnership) { create(:school_partnership, lead_provider_delivery_partnership:, school:) }

  let(:query_params) { { lead_provider:, school:, delivery_partner:, contract_period: } }

  describe '.school_partnerships' do
    subject { SchoolPartnerships::Query.new(**query_params) }

    before do
      allow(subject.scope).to receive(:earliest_first).and_call_original
      subject.school_partnerships
    end

    it 'returns the scope ordered by created_at, earliest first' do
      expect(subject.scope).to have_received(:earliest_first).once
    end

    it 'returns the scope contents' do
      expect(subject.school_partnerships).to match_array(subject.scope)
    end
  end

  describe '#exists?' do
    it 'returns true when a school partnership matches lead provider, delivery partner and school for the given registration period' do
      expect(SchoolPartnerships::Query.new(lead_provider:, school:, contract_period:)).to exist
    end

    describe 'registration periods' do
      context 'when contract_period differs' do
        subject { SchoolPartnerships::Query.new(**query_params.merge(contract_period: other_contract_period)) }

        let(:other_contract_period) { create(:contract_period, year: 2028) }

        it { is_expected.not_to(exist) }
      end

      context 'when contract_period omitted' do
        subject { SchoolPartnerships::Query.new(**query_params.except(:contract_period)) }

        it { is_expected.to(exist) }
      end
    end

    describe 'lead providers' do
      context 'when lead_provider differs' do
        subject { SchoolPartnerships::Query.new(**query_params.merge(lead_provider: other_lead_provider)) }

        let(:other_lead_provider) { create(:lead_provider) }

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

        let(:other_school) { create(:school) }

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

        let(:other_delivery_partner) { create(:delivery_partner) }

        it { is_expected.not_to(exist) }
      end

      context 'when delivery_partner omitted' do
        subject { SchoolPartnerships::Query.new(**query_params.except(:delivery_partner)) }

        it { is_expected.to(exist) }
      end
    end
  end
end
