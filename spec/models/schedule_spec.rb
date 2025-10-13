describe Schedule do
  describe 'relationships' do
    it { is_expected.to belong_to(:contract_period).inverse_of(:schedules).with_foreign_key(:contract_period_year) }
    it { is_expected.to have_many(:milestones) }
    it { is_expected.to have_many(:training_periods) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:contract_period_year).with_message('Enter a contract period year') }

    it 'only allows valid identifiers' do
      types = %w[extended reduced replacement standard]
      months = %w[april january september]
      valid_identifiers = types.product(months).map { |combination| ['ecf', *combination].join('-') }
      message = 'Choose an identifier from the list'

      expect(subject).to validate_inclusion_of(:identifier).in_array(valid_identifiers).with_message(message)
    end

    it 'ensures uniqueness of contract years and identifiers' do
      original = FactoryBot.create(:schedule)
      duplicate = original.dup

      expect(duplicate).not_to be_valid
      expect(duplicate.errors.messages.fetch(:identifier)).to include('Can be used once per contract period')
    end
  end
end
