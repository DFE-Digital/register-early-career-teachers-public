RSpec.describe CacheManager do
  let(:cache_manager) { described_class.instance }

  before do
    cache_manager.clear_all_caches!
  end

  describe '#cache_schools' do
    let!(:school1) { FactoryBot.create(:school, urn: 123_456) }
    let!(:school2) { FactoryBot.create(:school, urn: 789_012) }

    it 'loads all schools into cache' do
      expect(School.count).to eq(2)

      cache_manager.cache_schools

      expect(cache_manager.schools_by_urn[123_456]).to eq(school1)
      expect(cache_manager.schools_by_urn[789_012]).to eq(school2)
    end

    it 'uses batch processing' do
      expect(School).to receive(:find_each).with(batch_size: 3_000).and_call_original
      cache_manager.cache_schools
    end
  end

  describe '#cache_lead_providers' do
    let!(:lp1) { FactoryBot.create(:lead_provider, name: 'Provider A') }
    let!(:lp2) { FactoryBot.create(:lead_provider, name: 'Provider B') }

    it 'loads all lead providers into cache' do
      cache_manager.cache_lead_providers

      expect(cache_manager.lead_providers_by_name['Provider A']).to eq(lp1)
      expect(cache_manager.lead_providers_by_name['Provider B']).to eq(lp2)
    end
  end

  describe '#cache_delivery_partners' do
    let!(:dp1) { FactoryBot.create(:delivery_partner, name: 'Partner A') }
    let!(:dp2) { FactoryBot.create(:delivery_partner, name: 'Partner B') }

    it 'loads all delivery partners into cache' do
      cache_manager.cache_delivery_partners

      expect(cache_manager.delivery_partners_by_name['Partner A']).to eq(dp1)
      expect(cache_manager.delivery_partners_by_name['Partner B']).to eq(dp2)
    end
  end

  describe '#cache_active_lead_providers' do
    let!(:contract_period) { FactoryBot.create(:contract_period, year: 2023) }
    let!(:lead_provider) { FactoryBot.create(:lead_provider) }
    let!(:alp) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period_year: 2023) }

    it 'loads active lead providers with composite keys' do
      cache_manager.cache_active_lead_providers

      key = [lead_provider.id, 2023]
      expect(cache_manager.active_lead_providers_by_key[key]).to eq(alp)
    end

    it 'includes lead_provider association' do
      expect(ActiveLeadProvider).to receive(:includes).with(:lead_provider).and_call_original
      cache_manager.cache_active_lead_providers
    end
  end

  describe '#cache_school_partnerships' do
    let!(:contract_period) { FactoryBot.create(:contract_period, year: 2023) }
    let!(:school) { FactoryBot.create(:school) }
    let!(:lead_provider) { FactoryBot.create(:lead_provider) }
    let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period_year: 2023) }
    let!(:delivery_partner) { FactoryBot.create(:delivery_partner) }
    let!(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
    let!(:sp) { FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:) }

    it 'loads school partnerships with composite keys' do
      cache_manager.cache_school_partnerships

      key = [lead_provider_delivery_partnership.id, school.id]
      expect(cache_manager.school_partnerships_by_key[key]).to eq(sp)
    end

    it 'includes associations' do
      expect(SchoolPartnership).to receive(:includes).with(:lead_provider_delivery_partnership, :school).and_call_original
      cache_manager.cache_school_partnerships
    end
  end

  describe '#cache_teachers' do
    let!(:teacher1) { FactoryBot.create(:teacher, trn: '1234567') }
    let!(:teacher2) { FactoryBot.create(:teacher, trn: '7654321') }

    it 'loads all teachers into cache' do
      cache_manager.cache_teachers

      expect(cache_manager.teachers_by_trn['1234567']).to eq(teacher1)
      expect(cache_manager.teachers_by_trn['7654321']).to eq(teacher2)
    end
  end

  describe '#cache_statements' do
    let!(:contract_period) { FactoryBot.create(:contract_period, year: 2023) }
    let!(:lead_provider) { FactoryBot.create(:lead_provider) }
    let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period_year: 2023) }
    let!(:statement1) { FactoryBot.create(:statement, active_lead_provider:) }
    let!(:statement2) { FactoryBot.create(:statement, active_lead_provider:) }

    it 'loads all statements into cache' do
      # Ensure statements are in database before caching
      expect(Statement.count).to eq(2)

      cache_manager.cache_statements

      expect(cache_manager.statements_by_api_id[statement1.api_id]).to eq(statement1)
      expect(cache_manager.statements_by_api_id[statement2.api_id]).to eq(statement2)
    end
  end

  describe '#clear_all_caches!' do
    it 'clears all cache stores' do
      # Populate some caches
      FactoryBot.create(:school, urn: 123_456)
      FactoryBot.create(:teacher, trn: '1234567')
      cache_manager.cache_schools
      cache_manager.cache_teachers

      expect(cache_manager.schools_by_urn).not_to be_empty
      expect(cache_manager.teachers_by_trn).not_to be_empty

      # Clear all caches
      cache_manager.clear_all_caches!

      expect(cache_manager.schools_by_urn).to be_empty
      expect(cache_manager.teachers_by_trn).to be_empty
      expect(cache_manager.lead_providers_by_name).to be_empty
      expect(cache_manager.delivery_partners_by_name).to be_empty
      expect(cache_manager.active_lead_providers_by_key).to be_empty
      expect(cache_manager.school_partnerships_by_key).to be_empty
      expect(cache_manager.statements_by_api_id).to be_empty
    end
  end

  describe '#cache_teacher' do
    let!(:teacher) { FactoryBot.create(:teacher, trn: '1234567') }

    it 'adds individual teacher to cache' do
      cache_manager.cache_teacher(teacher)

      expect(cache_manager.teachers_by_trn['1234567']).to eq(teacher)
    end
  end

  describe 'find methods' do
    let!(:contract_period_2023) { FactoryBot.create(:contract_period, year: 2023) }
    let!(:contract_period_2024) { FactoryBot.create(:contract_period, year: 2024) }
    let!(:school) { FactoryBot.create(:school, urn: 123_456) }
    let!(:lead_provider) { FactoryBot.create(:lead_provider, name: 'Provider A') }
    let!(:delivery_partner) { FactoryBot.create(:delivery_partner, name: 'Partner A') }
    let!(:teacher) { FactoryBot.create(:teacher, trn: '1234567') }
    let!(:contract_period) { FactoryBot.create(:contract_period, year: 2023) }
    let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period_year: 2023) }
    let!(:statement) { FactoryBot.create(:statement, active_lead_provider:) }
    let!(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }
    let!(:school_partnership) { FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership:) }

    before do
      cache_manager.cache_schools
      cache_manager.cache_lead_providers
      cache_manager.cache_delivery_partners
      cache_manager.cache_teachers
      cache_manager.cache_statements
      cache_manager.cache_active_lead_providers
      cache_manager.cache_school_partnerships
    end

    describe '#find_school_by_urn' do
      it 'returns cached school when found' do
        expect(cache_manager.find_school_by_urn(123_456)).to eq(school)
      end

      it 'returns nil when school not found' do
        expect(cache_manager.find_school_by_urn(999_999)).to be_nil
      end

      it 'falls back to database and caches result' do
        new_school = FactoryBot.create(:school, urn: 654_321)
        expect(cache_manager.find_school_by_urn(654_321)).to eq(new_school)
        expect(cache_manager.schools_by_urn[654_321]).to eq(new_school)
      end
    end

    describe '#find_lead_provider_by_name' do
      it 'returns cached lead provider when found' do
        expect(cache_manager.find_lead_provider_by_name('Provider A')).to eq(lead_provider)
      end

      it 'returns nil when lead provider not found' do
        expect(cache_manager.find_lead_provider_by_name('Unknown Provider')).to be_nil
      end

      it 'falls back to database and caches result' do
        new_lp = FactoryBot.create(:lead_provider, name: 'New Provider')
        expect(cache_manager.find_lead_provider_by_name('New Provider')).to eq(new_lp)
        expect(cache_manager.lead_providers_by_name['New Provider']).to eq(new_lp)
      end
    end

    describe '#find_delivery_partner_by_name' do
      it 'returns cached delivery partner when found' do
        expect(cache_manager.find_delivery_partner_by_name('Partner A')).to eq(delivery_partner)
      end

      it 'returns nil when delivery partner not found' do
        expect(cache_manager.find_delivery_partner_by_name('Unknown Partner')).to be_nil
      end
    end

    describe '#find_teacher_by_trn' do
      it 'returns cached teacher when found' do
        expect(cache_manager.find_teacher_by_trn('1234567')).to eq(teacher)
      end

      it 'returns nil when teacher not found' do
        expect(cache_manager.find_teacher_by_trn('9999999')).to be_nil
      end
    end

    describe '#find_statement_by_api_id' do
      it 'returns cached statement when found' do
        expect(cache_manager.find_statement_by_api_id(statement.api_id)).to eq(statement)
      end

      it 'returns nil when statement not found' do
        expect(cache_manager.find_statement_by_api_id('unknown_stmt')).to be_nil
      end
    end

    describe '#find_active_lead_provider' do
      it 'returns cached active lead provider when found' do
        cache_manager.find_active_lead_provider(lead_provider_id: lead_provider.id, contract_period_year: 2023)
        expect(cache_manager.active_lead_providers_by_key[[lead_provider.id, 2023]]).to eq(active_lead_provider)
      end

      it 'returns nil when not found' do
        result = cache_manager.find_active_lead_provider(lead_provider_id: 999, contract_period_year: 2023)
        expect(result).to be_nil
      end

      it 'falls back to database and caches result' do
        new_alp = FactoryBot.create(:active_lead_provider, lead_provider:, contract_period_year: 2024)
        result = cache_manager.find_active_lead_provider(lead_provider_id: lead_provider.id, contract_period_year: 2024)
        expect(result).to eq(new_alp)

        key = [lead_provider.id, 2024]
        expect(cache_manager.active_lead_providers_by_key[key]).to eq(new_alp)
      end
    end

    describe '#find_school_partnership' do
      it 'returns cached school partnership when found' do
        result = cache_manager.find_school_partnership(lead_provider_delivery_partnership_id: lead_provider_delivery_partnership.id, school_id: school.id)
        expect(result).to eq(school_partnership)
      end

      it 'returns nil when not found' do
        result = cache_manager.find_school_partnership(lead_provider_delivery_partnership_id: 999, school_id: school.id)
        expect(result).to be_nil
      end
    end
  end

  describe 'singleton behavior' do
    it 'returns the same instance' do
      instance1 = described_class.instance
      instance2 = described_class.instance
      expect(instance1).to eq(instance2)
    end

    it 'maintains state between calls' do
      school = FactoryBot.create(:school, urn: 123_456)
      cache_manager.cache_schools

      FactoryBot.create(:school, urn: 654_321)
      cache_manager.cache_schools

      expect(cache_manager.find_school_by_urn(123_456)).to eq(school)
    end
  end
end
