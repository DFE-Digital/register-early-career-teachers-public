RSpec.describe Schools::Validation::ECTStartDate do
  describe '#valid?' do
    subject { described_class.new(date_as_hash:) }

    let(:cut_off_date) { Date.new(2024, 6, 1) }
    let(:date_as_hash) { {} }

    before do
      allow(ContractPeriod).to receive(:earliest_permitted_start_date).and_return(cut_off_date)
    end

    context 'when the date is before the cut off' do
      let(:date_as_hash) { { 1 => 2024, 2 => 5, 3 => 31 } }

      it 'is not valid and returns the correct error message' do
        expect(subject).not_to be_valid
        expect(subject.error_message).to eq('Start date cannot be earlier than the last 2 registration periods. Enter a date later than 1 June 2024')
      end
    end

    context 'when the date is exactly on the cut off' do
      let(:date_as_hash) { { 1 => 2024, 2 => 6, 3 => 1 } }

      it 'is valid and has no error message' do
        expect(subject).to be_valid
        expect(subject.error_message).to be_blank
      end
    end

    context 'when the date is after the cut off' do
      let(:date_as_hash) { { 1 => 2024, 2 => 6, 3 => 2 } }

      it 'is valid and has no error message' do
        expect(subject).to be_valid
        expect(subject.error_message).to be_blank
      end
    end

    context 'when the cut off is nil (no current contract period)' do
      let(:cut_off_date) { nil }
      let(:date_as_hash) { { 1 => 2024, 2 => 6, 3 => 1 } }

      it 'is valid and has no error message' do
        expect(subject).to be_valid
        expect(subject.error_message).to be_blank
      end
    end
  end
end
