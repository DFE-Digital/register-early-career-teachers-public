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
    subject { described_class.new(worker: 0) }

    let!(:cohort1) { FactoryBot.create(:migration_cohort, start_year: 2021) }
    let!(:cohort2) { FactoryBot.create(:migration_cohort, start_year: 2022) }
    let!(:data_migration) { FactoryBot.create(:data_migration, model: :registration_period) }
    let(:registration_period) { RegistrationPeriod.find_by(year: cohort1.start_year) }

    before { subject.migrate! }

    it 'creates a registration period for each cohort' do
      expect(RegistrationPeriod.count).to eq(2)
      expect(RegistrationPeriod.pluck(:year)).to contain_exactly(2021, 2022)
    end

    it 'sets the registration period started_on to match the cohort registration_start_date' do
      expect(registration_period.started_on).to eq(cohort1.registration_start_date)
    end

    it 'sets the registration period finished_on to one year after started_on, minus one day' do
      expect(registration_period.finished_on).to eq(registration_period.started_on.next_year.prev_day)
    end
  end
end
