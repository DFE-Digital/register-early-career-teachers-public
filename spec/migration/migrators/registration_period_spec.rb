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
    before { allow(::RegistrationPeriod).to receive_message_chain(:connection, :execute) }

    context 'when migration testing is enabled' do
      it 'truncates the registration periods table' do
        allow(Rails.application.config).to receive(:enable_migration_testing).and_return(true)
        expect(::RegistrationPeriod.connection).to receive(:execute) do |sql|
          expect(sql).to include('TRUNCATE')
          expect(sql).to include(::RegistrationPeriod.table_name)
        end
        described_class.reset!
      end
    end

    context 'when migration testing is disabled' do
      it 'does not truncate the table' do
        allow(Rails.application.config).to receive(:enable_migration_testing).and_return(false)
        expect(::RegistrationPeriod.connection).not_to receive(:execute)
        described_class.reset!
      end
    end
  end

  describe '#migrate!' do
    let!(:cohort1) { FactoryBot.create(:migration_cohort, start_year: 2021) }
    let!(:cohort2) { FactoryBot.create(:migration_cohort, start_year: 2022) }
    let!(:data_migration) { DataMigration.create!(model: :registration_period, worker: 0) }

    it 'creates registration periods with cohort start years as IDs' do
      expect {
        described_class.new(worker: 0).migrate!
      }.to change { RegistrationPeriod.count }.by(2)
      expect(RegistrationPeriod.pluck(:id)).to contain_exactly(2021, 2022)
    end
  end
end
