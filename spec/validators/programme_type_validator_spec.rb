RSpec.describe ProgrammeTypeValidator, type: :model do
  subject { test_class.new(programme_type:) }

  let(:test_class) do
    Class.new do
      include ActiveModel::Model
      attr_accessor :programme_type

      validates :programme_type, programme_type: true
    end
  end

  context 'when programme_type is valid' do
    %w[provider_led school_led].each do |valid_value|
      let(:programme_type) { valid_value }

      it "is valid when programme_type is '#{valid_value}'" do
        expect(subject).to be_valid
      end
    end
  end

  context 'when programme_type is invalid' do
    context 'is invalid when programme_type is nil' do
      let(:programme_type) { nil }

      it 'it adds an error' do
        expect(subject).not_to be_valid
        expect(subject.errors[:programme_type]).to include("Select either 'Provider-led' or 'School-led' training")
      end
    end

    context 'is invalid when programme_type is an unrecognized value' do
      let(:programme_type) { 'Invalid-value' }

      it 'adds an error' do
        expect(subject).not_to be_valid
        expect(subject.errors[:programme_type]).to include("'Invalid-value' is not a valid programme type")
      end
    end
  end
end
