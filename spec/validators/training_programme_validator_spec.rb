RSpec.describe TrainingProgrammeValidator, type: :model do
  subject { test_class.new(training_programme:) }

  let(:test_class) do
    Class.new do
      include ActiveModel::Model
      attr_accessor :training_programme

      validates :training_programme, training_programme: true
    end
  end

  context 'when training_programme is valid' do
    %w[provider_led school_led].each do |valid_value|
      let(:training_programme) { valid_value }

      it "is valid when training_programme is '#{valid_value}'" do
        expect(subject).to be_valid
      end
    end
  end

  context 'when training_programme is invalid' do
    context 'is invalid when training_programme is nil' do
      let(:training_programme) { nil }

      it 'adds an error' do
        expect(subject).not_to be_valid
        expect(subject.errors[:training_programme]).to include("Select either 'Provider-led' or 'School-led' training")
      end
    end

    context 'is invalid when training_programme is an unrecognized value' do
      let(:training_programme) { 'Invalid-value' }

      it 'adds an error' do
        expect(subject).not_to be_valid
        expect(subject.errors[:training_programme]).to include("'Invalid-value' is not a valid programme type")
      end
    end
  end
end
