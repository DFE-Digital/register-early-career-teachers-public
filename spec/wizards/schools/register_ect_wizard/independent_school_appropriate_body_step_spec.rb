RSpec.describe Schools::RegisterECTWizard::IndependentSchoolAppropriateBodyStep, type: :model do
  subject { described_class.new(wizard:, appropriate_body_id: '123') }

  let(:school) { FactoryBot.create(:school, :independent) }
  let(:store) { FactoryBot.build(:session_repository, appropriate_body_id: '123') }
  let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :independent_school_appropriate_body, store:, school:) }

  describe "inheritance" do
    it "inherits from AppropriateBodyStep" do
      expect(subject).to be_a(Schools::RegisterECTWizard::AppropriateBodyStep)
    end
  end

  describe '#initialize' do
    subject { described_class.new(wizard:, **params) }

    let(:appropriate_body_id) { 'provided_id' }
    let(:appropriate_body_type) { 'provided_type' }

    context 'when the appropriate_body_id is provided' do
      let(:params) { { appropriate_body_id:, appropriate_body_type: } }

      context "when the type is 'national'" do
        let(:appropriate_body_type) { 'national' }
        let!(:istip) { FactoryBot.create(:appropriate_body, :istip) }

        it 'populate the instance from ISTIP' do
          expect(subject.appropriate_body_id).to eq(istip.id.to_s)
        end
      end

      context "when the type is not 'national'" do
        let(:appropriate_body_id) { '5678' }

        it 'populate the instance from the arguments' do
          expect(subject.appropriate_body_id).to eq('5678')
        end
      end
    end

    context 'when no attributes are provided' do
      let(:params) { {} }

      it 'populate it from the wizard store' do
        expect(subject.appropriate_body_id).to eq('123')
      end
    end
  end

  describe 'validations' do
    subject { described_class.new(wizard:, appropriate_body_id:, appropriate_body_type:) }

    context 'when the appropriate_body is a national' do
      let(:appropriate_body_id) { FactoryBot.create(:appropriate_body, :istip).id }
      let(:appropriate_body_type) { 'national' }

      it 'adds no error' do
        expect(subject).to be_valid
      end
    end

    context 'when the appropriate_body is a teaching school hub' do
      let(:appropriate_body_id) { FactoryBot.create(:appropriate_body, :teaching_school_hub).id }
      let(:appropriate_body_type) { 'teaching_school_hub' }

      it 'adds no error' do
        expect(subject).to be_valid
      end
    end
  end
end
