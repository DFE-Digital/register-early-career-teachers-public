RSpec.describe RegisterECTHelper, type: :helper do
  describe '#academic_year_string' do
    it 'returns the correct formatted academic year string' do
      expect(academic_year_string(2024)).to eq('2024 to 2025')
    end
  end

  describe '#formatted_year_range_for_registration_date' do
    let(:date) { Date.new(2024, 4, 10) }

    context 'when a registration period exists for the date' do
      it 'returns the correct formatted academic year string' do
        registration_period = double('RegistrationPeriod', year: 2023)
        allow(RegistrationPeriod).to receive(:ongoing_on).with(date).and_return([registration_period])

        expect(formatted_year_range_for_registration_date(date)).to eq('2023 to 2024')
      end
    end

    context 'when no registration period exists for the date' do
      it 'returns an empty string' do
        allow(RegistrationPeriod).to receive(:ongoing_on).with(date).and_return([])

        expect(formatted_year_range_for_registration_date(date)).to eq('')
      end
    end
  end
end
