RSpec.describe Schools::Validation::HashDate do
  subject(:hash_date) { described_class.new(date_hash) }

  before { hash_date.valid? }

  context 'when value is not a real date' do
    let(:date_hash) do
      {
        1 => '2022',
        2 => '2',
        3 => '30'
      }
    end

    it { expect(hash_date).not_to be_valid }
    it { expect(hash_date.error_message).to eq('Enter the date in the correct format, for example 12 03 1998') }
  end

  context 'when value includes negative numbers' do
    let(:date_hash) do
      {
        1 => '2022',
        2 => '2',
        3 => '-28'
      }
    end

    it { expect(hash_date).not_to be_valid }
    it { expect(hash_date.error_message).to eq('Enter the date in the correct format, for example 12 03 1998') }
  end
end
