RSpec.describe Schools::RegisterECTWizard::RegistrationSession::Presenter do
  subject(:presenter) { described_class.new(context:) }

  let(:context) do
    Struct.new(:corrected_name, :trs_full_name, :working_pattern, :trs_date_of_birth)
      .new(corrected_name, trs_full_name, working_pattern, trs_date_of_birth)
  end
  let(:corrected_name) { nil }
  let(:trs_full_name) { 'Marge Simpson' }
  let(:working_pattern) { 'part_time' }
  let(:trs_date_of_birth) { Date.new(1980, 5, 12) }

  describe '#full_name' do
    it 'returns the TRS full name when corrected name is blank' do
      expect(presenter.full_name).to eq('Marge Simpson')
    end

    context 'when a corrected name is present' do
      let(:corrected_name) { '  Marjorie Simpson  ' }

      it 'returns the trimmed corrected name' do
        expect(presenter.full_name).to eq('Marjorie Simpson')
      end
    end
  end

  describe '#formatted_working_pattern' do
    it 'humanizes the working pattern' do
      expect(presenter.formatted_working_pattern).to eq('Part time')
    end

    context 'when working pattern is missing' do
      let(:working_pattern) { nil }

      it 'returns nil' do
        expect(presenter.formatted_working_pattern).to be_nil
      end
    end
  end

  describe '#govuk_date_of_birth' do
    it 'formats the TRS date of birth' do
      expect(presenter.govuk_date_of_birth).to eq('12 May 1980')
    end

    context 'when TRS date of birth is missing' do
      let(:trs_date_of_birth) { nil }

      it 'returns nil' do
        expect(presenter.govuk_date_of_birth).to be_nil
      end
    end
  end
end
