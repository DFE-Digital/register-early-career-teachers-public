RSpec.describe AppropriateBodyValidator, type: :model do
  subject { test_class.new(appropriate_body_id:, school:) }

  let(:school) { double(state_funded?: false) }

  let(:test_class) do
    Class.new do
      include ActiveModel::Model
      attr_accessor :appropriate_body_id, :school

      validates :appropriate_body, appropriate_body: true

      def appropriate_body
        @appropriate_body ||= AppropriateBody.find_by_id(appropriate_body_id) if appropriate_body_id
      end
    end
  end

  context 'when the appropriate_body_id is blank' do
    let(:appropriate_body_id) { nil }

    it 'adds an error' do
      expect(subject).not_to be_valid
      expect(subject.errors[:appropriate_body]).to include("Select the appropriate body which will be supporting the ECT's induction")
    end
  end

  context 'when the appropriate_body is not registered' do
    let(:appropriate_body_id) { '999999999' }

    it 'add an error' do
      expect(subject).not_to be_valid
      expect(subject.errors[:appropriate_body]).to include("Select the appropriate body which will be supporting the ECT's induction")
    end
  end

  context 'when the appropriate_body is a local authority' do
    let(:appropriate_body_id) { create(:appropriate_body, :local_authority) }

    it 'adds an error' do
      expect(subject).not_to be_valid
      expect(subject.errors[:appropriate_body]).to include("Select a valid appropriate body which will be supporting the ECT's induction")
    end
  end

  context 'when the school is state funded' do
    let(:school) { double(state_funded?: true) }

    context 'when the appropriate_body is a national' do
      let(:appropriate_body_id) { create(:appropriate_body, :national) }

      it 'add an error' do
        expect(subject).not_to be_valid
        expect(subject.errors[:appropriate_body]).to include("Select a teaching school hub appropriate body which will be supporting the ECT's induction")
      end
    end

    context 'when the appropriate_body is a teaching school hub' do
      let(:appropriate_body_id) { create(:appropriate_body, :teaching_school_hub) }

      it 'adds no error' do
        expect(subject).to be_valid
      end
    end
  end

  context 'when the school is independent' do
    let(:school) { double(state_funded?: false) }

    context 'when the appropriate_body is a national' do
      let(:appropriate_body_id) { create(:appropriate_body, :national) }

      it 'adds no error' do
        expect(subject).to be_valid
      end
    end

    context 'when the appropriate_body is a teaching school hub' do
      let(:appropriate_body_id) { create(:appropriate_body, :teaching_school_hub) }

      it 'adds no error' do
        expect(subject).to be_valid
      end
    end
  end
end
