describe Milestone do
  let(:declaration_types) { %w[started retained-1 retained-2 retained-3 retained-4 completed extended-1 extended-2 extended-3] }

  describe 'relationships' do
    it { is_expected.to belong_to(:schedule) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:schedule_id).with_message('Choose a schedule') }
    it { is_expected.to validate_presence_of(:start_date).with_message('Enter a start date') }
    it { is_expected.to validate_inclusion_of(:declaration_type).in_array(declaration_types).with_message('Choose a valid declaration type') }

    it 'ensures uniqueness of declaration_types and schedule_ids' do
      original = FactoryBot.create(:milestone)
      duplicate = original.dup

      expect(duplicate).not_to be_valid
      expect(duplicate.errors.messages.fetch(:declaration_type)).to include('Can be used once per schedule')
    end
  end

  describe 'ordering' do
    let(:declaration_types_in_the_wrong_order) { %w[extended-1 retained-2 retained-3 completed started extended-3 retained-1 retained-4 extended-2] }

    before do
      declaration_types_in_the_wrong_order.each do |declaration_type|
        FactoryBot.create(:milestone, declaration_type:)
      end
    end

    it 'orders by the declaration_type' do
      expect(Milestone.in_declaration_order.map(&:declaration_type)).to eql(declaration_types)
    end
  end
end
