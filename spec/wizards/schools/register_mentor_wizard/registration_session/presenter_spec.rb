RSpec.describe Schools::RegisterMentorWizard::RegistrationSession::Presenter do
  subject(:presenter) { described_class.new(registration_session:) }

  let(:registration_session) do
    Struct.new(:corrected_name, :trs_first_name, :trs_last_name, :trs_date_of_birth)
          .new(corrected_name, trs_first_name, trs_last_name, trs_date_of_birth)
  end
  let(:corrected_name) { nil }
  let(:trs_first_name) { 'Dusty' }
  let(:trs_last_name) { 'Rhodes' }
  let(:trs_date_of_birth) { Date.new(1975, 6, 1) }

  describe '#full_name' do
    it 'falls back to the TRS full name when no corrected name is present' do
      expect(presenter.full_name).to eq('Dusty Rhodes')
    end

    context 'when a corrected name is provided' do
      let(:corrected_name) { '  Randall Marsh  ' }

      it 'returns the trimmed corrected name' do
        expect(presenter.full_name).to eq('Randall Marsh')
      end
    end

    context 'when both corrected and TRS names are missing' do
      let(:corrected_name) { nil }
      let(:trs_first_name) { nil }
      let(:trs_last_name) { nil }

      it 'returns nil' do
        expect(presenter.full_name).to be_nil
      end
    end
  end

  describe '#govuk_date_of_birth' do
    it 'formats the TRS date of birth using the GOV.UK format' do
      expect(presenter.govuk_date_of_birth).to eq('1 June 1975')
    end
  end

  describe '#trs_full_name' do
    it 'joins the TRS first and last names with a space' do
      expect(presenter.trs_full_name).to eq('Dusty Rhodes')
    end

    context 'when only trs_first_name is present' do
      let(:trs_last_name) { nil }

      it 'returns the first name without trailing spaces' do
        expect(presenter.trs_full_name).to eq('Dusty')
      end
    end
  end
end
