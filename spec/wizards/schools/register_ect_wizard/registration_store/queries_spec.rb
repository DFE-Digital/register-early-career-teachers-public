RSpec.describe Schools::RegisterECTWizard::RegistrationStore::Queries do
  subject(:queries) { described_class.new(registration_store:) }

  let(:teacher) { FactoryBot.create(:teacher) }
  let(:trn) { teacher.trn }
  let(:registration_store) do
    Struct.new(:trn, :appropriate_body_id, :lead_provider_id, :start_date, :ect_at_school_period_id)
      .new(trn, appropriate_body_id, lead_provider_id, start_date, ect_at_school_period_id)
  end

  let(:appropriate_body_id) { nil }
  let(:lead_provider_id) { nil }
  let(:start_date) { nil }
  let(:ect_at_school_period_id) { nil }

  describe '#ect_at_school_period' do
    context 'when the stored ect_at_school_period_id is present' do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period) }
      let(:ect_at_school_period_id) { ect_at_school_period.id }

      it 'returns the matching ECT at school period' do
        expect(queries.ect_at_school_period).to eq(ect_at_school_period)
      end
    end

    context 'when the stored ect_at_school_period_id is blank' do
      it 'returns nil' do
        expect(queries.ect_at_school_period).to be_nil
      end
    end
  end

  describe '#active_record_at_school' do
    let(:school) { FactoryBot.create(:school) }
    let!(:ongoing_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:) }

    it 'returns the ongoing period for the given urn' do
      expect(queries.active_record_at_school(school.urn)).to eq(ongoing_period)
    end
  end

  describe '#contract_start_date' do
    context 'when the start_date is present' do
      let(:contract_period) { FactoryBot.create(:contract_period, year: 2024) }
      let(:start_date) { (contract_period.started_on + 1.day).to_s }

      it 'returns the contract period containing the date' do
        expect(queries.contract_start_date).to eq(contract_period)
      end
    end

    context 'when the start_date is blank' do
      it 'returns nil' do
        expect(queries.contract_start_date).to be_nil
      end
    end
  end

  describe '#lead_providers_within_contract_period' do
    context 'when there is no contract period' do
      it 'returns an empty array without hitting the database' do
        expect(LeadProviders::Active).not_to receive(:in_contract_period)

        expect(queries.lead_providers_within_contract_period).to eq([])
      end
    end

    context 'when a contract period is present' do
      let(:contract_period) { FactoryBot.create(:contract_period, year: 2025) }
      let(:start_date) { (contract_period.started_on + 2.days).to_s }
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:another_lead_provider) { FactoryBot.create(:lead_provider) }

      before do
        FactoryBot.create(:active_lead_provider, contract_period:, lead_provider:)
        FactoryBot.create(:active_lead_provider, contract_period:, lead_provider: another_lead_provider)
      end

      it 'returns the active lead providers for the contract period' do
        ids = queries.lead_providers_within_contract_period.map(&:id)

        expect(ids).to contain_exactly(lead_provider.id, another_lead_provider.id)
      end
    end
  end

  describe 'previous registration queries' do
    let!(:previous_ect_period) do
      FactoryBot.create(:ect_at_school_period,
                        teacher:,
                        started_on: 2.years.ago,
                        finished_on: 1.year.ago)
    end
    let!(:training_period) do
      FactoryBot.create(:training_period,
                        :for_ect,
                        ect_at_school_period: previous_ect_period,
                        started_on: previous_ect_period.started_on,
                        finished_on: previous_ect_period.finished_on)
    end
    let(:previous_delivery_partner) { training_period.school_partnership.lead_provider_delivery_partnership.delivery_partner }
    let(:previous_lead_provider) { training_period.school_partnership.lead_provider_delivery_partnership.lead_provider }
    let(:previous_school) { previous_ect_period.school }
    let(:previous_appropriate_body) { FactoryBot.create(:appropriate_body) }

    before do
      FactoryBot.create(:induction_period,
                        teacher:,
                        appropriate_body: previous_appropriate_body,
                        started_on: previous_ect_period.started_on,
                        finished_on: previous_ect_period.finished_on)
    end

    it 'returns the previous ect at school period' do
      expect(queries.previous_ect_at_school_period).to eq(previous_ect_period)
    end

    it 'returns the previous training period' do
      expect(queries.previous_training_period).to eq(training_period)
    end

    it 'returns the previous appropriate body' do
      expect(queries.previous_appropriate_body).to eq(previous_appropriate_body)
    end

    it 'returns the previous delivery partner' do
      expect(queries.previous_delivery_partner).to eq(previous_delivery_partner)
    end

    it 'returns the previous lead provider' do
      expect(queries.previous_lead_provider).to eq(previous_lead_provider)
    end

    it 'returns the previous school' do
      expect(queries.previous_school).to eq(previous_school)
    end
  end
end
