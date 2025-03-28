RSpec.describe AppropriateBodyValidator, type: :model do
  subject { test_class.new(appropriate_body_type:, appropriate_body_id:) }

  let(:test_class) do
    Class.new do
      include ActiveModel::Model
      attr_accessor :appropriate_body_type, :appropriate_body_id

      validates_with AppropriateBodyValidator
    end
  end
  let(:appropriate_body_type) { '' }
  let(:appropriate_body_id) { '' }

  context 'when the appropriate_body_type is blank' do
    it 'is not valid' do
      expect(subject).not_to be_valid
      expect(subject.errors[:appropriate_body_type]).to include("Select the appropriate body which will be supporting the ECT's induction")
    end
  end

  context 'when appropriate_body_type is teaching_school_hub' do
    let(:appropriate_body_type) { 'teaching_school_hub' }

    context 'and appropriate_body_id is blank' do
      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:appropriate_body_id]).to include("Enter the name of the appropriate body which will be supporting the ECT's induction")
      end
    end

    context 'and appropriate_body_id is present' do
      let(:appropriate_body_id) { '1' }

      it { expect(subject).to be_valid }
    end
  end

  context 'when appropriate_body_type is not teaching_school_hub' do
    let(:appropriate_body_type) { 'other_type' }

    it { expect(subject).to be_valid }
  end
end
