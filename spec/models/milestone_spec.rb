describe Milestone do
  describe 'relationships' do
    it { is_expected.to belong_to(:schedule) }
  end

  describe 'validation' do
    let(:declaration_types) { %w[started retained-1 retained-2 retained-3 retained-4 completed extended-1 extended-2 extended-3] }

    it { is_expected.to validate_presence_of(:schedule_id).with_message('Choose a schedule') }
    it { is_expected.to validate_presence_of(:start_date).with_message('Enter a start date') }
    it { is_expected.to validate_inclusion_of(:declaration_type).in_array(declaration_types).with_message('Choose a valid declaration type') }
  end
end
