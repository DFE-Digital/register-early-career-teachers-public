RSpec.describe Schools::Validation::MentorStartDate do
  describe '#valid?' do
    subject { described_class.new(date_as_hash:) }

    let(:date_as_hash) { {} }

    context 'when date is empty' do
      it 'returns error' do
        expect(subject).not_to be_valid
        expect(subject.error_message).to eq("Enter the date they started or will start ECT mentoring at your school")
      end
    end

    context 'when the date is valid' do
      let(:date_as_hash) { { 1 => 2024, 2 => 6, 3 => 1 } }

      it 'is valid and has no error message' do
        expect(subject).to be_valid
        expect(subject.error_message).to be_blank
      end
    end

    context 'when day is missing' do
      let(:date_as_hash) { { 1 => 2024, 2 => 6, 3 => nil } }

      it 'returns error' do
        expect(subject).not_to be_valid
        expect(subject.error_message).to eq("Enter the date in the correct format, for example 12 03 1998")
      end
    end

    context 'when month is missing' do
      let(:date_as_hash) { { 1 => 2024, 2 => nil, 3 => 1 } }

      it 'returns error' do
        expect(subject).not_to be_valid
        expect(subject.error_message).to eq("Enter the date in the correct format, for example 12 03 1998")
      end
    end

    context 'when year is missing' do
      let(:date_as_hash) { { 1 => nil, 2 => 6, 3 => 1 } }

      it 'returns error' do
        expect(subject).not_to be_valid
        expect(subject.error_message).to eq("Enter the date in the correct format, for example 12 03 1998")
      end
    end
  end
end
