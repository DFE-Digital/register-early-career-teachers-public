RSpec.describe WorkingPatternValidator, type: :model do
  let(:test_class) do
    Class.new do
      include ActiveModel::Model
      attr_accessor :working_pattern

      validates :working_pattern, working_pattern: true
    end
  end

  subject { test_class.new(working_pattern:) }

  context 'when working_pattern is valid' do
    %w[part_time full_time].each do |valid_value|
      let(:working_pattern) { valid_value }

      it "is valid when working_pattern is '#{valid_value}'" do
        expect(subject).to be_valid
      end
    end
  end

  context 'when working_pattern is invalid' do
    context 'is invalid when working_pattern is nil' do
      let(:working_pattern) { nil }

      it 'it adds an error' do
        expect(subject).to_not be_valid
        expect(subject.errors[:working_pattern]).to include("Select if the ECT's working pattern is full or part time")
      end
    end

    context 'is invalid when working_pattern is an unrecognized value' do
      let(:working_pattern) { 'Invalid-value' }

      it 'adds an error' do
        expect(subject).to_not be_valid
        expect(subject.errors[:working_pattern]).to include("'Invalid-value' is not a valid working pattern")
      end
    end
  end
end
