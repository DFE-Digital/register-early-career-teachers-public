describe Milestone do
  describe 'relationships' do
    it { is_expected.to belong_to(:schedule) }
  end

  describe 'validation' do
    let(:declaration_types) { %w[started retained-1 retained-2 retained-3 retained-4 completed extended-1 extended-2 extended-3] }

    it { is_expected.to validate_presence_of(:schedule_id).with_message('Choose a schedule') }
    it { is_expected.to validate_presence_of(:start_date).with_message('Enter a start date') }
    it { is_expected.to validate_inclusion_of(:declaration_type).in_array(declaration_types).with_message('Choose a valid declaration type') }

    it 'ensures uniqueness of declaraion_types and schedule_ids' do
      original = FactoryBot.create(:milestone)
      duplicate = original.dup

      expect(duplicate).not_to be_valid
      expect(duplicate.errors.messages.fetch(:declaration_type)).to include('Can be used once per schedule')
    end
  end
end
