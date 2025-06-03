RSpec.describe Migrators::RegistrationPeriod do
  describe '.record_count' do
    it 'returns the count of cohorts' do
      FactoryBot.create_list(:migration_cohort, 2, :with_sequential_start_year)
      expect(described_class.record_count).to eq(2)
    end
  end

  describe '.model' do
    it 'returns :registration_period' do
      expect(described_class.model).to eq(:registration_period)
    end
  end

  describe '.cohorts' do
    it 'returns all cohorts' do
      cohort = FactoryBot.create(:migration_cohort)
      expect(described_class.cohorts).to include(cohort)
    end
  end

  describe '.reset!' do
    before do
      FactoryBot.create(:registration_period)
      allow(Rails.application.config).to receive(:enable_migration_testing).and_return(enable_migration_testing)
    end

    context 'when migration testing is enabled' do
      let(:enable_migration_testing) { true }

      it 'removes all records from the registration_periods table' do
        expect { described_class.reset! }.to change(RegistrationPeriod, :count).from(1).to(0)
      end
    end

    context 'when migration testing is disabled' do
      let(:enable_migration_testing) { false }

      it 'does not remove records from the registration_periods table' do
        expect { described_class.reset! }.not_to(change(RegistrationPeriod, :count))
      end
    end
  end

  describe '#migrate!' do
    let!(:cohort1) { FactoryBot.create(:migration_cohort, start_year: 2021) }
    let!(:cohort2) { FactoryBot.create(:migration_cohort, start_year: 2022) }
    let!(:data_migration) { FactoryBot.create(:data_migration, model: :registration_period) }

    it 'creates registration periods with cohort start years as IDs' do
      expect {
        described_class.new(worker: 0).migrate!
      }.to change(RegistrationPeriod, :count).by(2)
      expect(RegistrationPeriod.pluck(:year)).to contain_exactly(2021, 2022)
    end
  end
end
