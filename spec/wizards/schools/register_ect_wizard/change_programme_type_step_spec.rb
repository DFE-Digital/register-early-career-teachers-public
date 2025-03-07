RSpec.describe Schools::RegisterECTWizard::ChangeProgrammeTypeStep, type: :model do
  let(:lead_provider) { double(name: 'Acme Lead Provider') }
  let(:programme_type) { 'school_led' }
  let(:new_programme_type) { 'provider_led' }
  let(:school) { FactoryBot.create(:school, :independent) }
  let(:store) { FactoryBot.build(:session_repository, programme_type:, lead_provider:) }
  let(:wizard) { FactoryBot.build(:register_ect_wizard, current_step: :change_programme_type, store:, school:) }

  subject { described_class.new(wizard:, programme_type: new_programme_type) }

  describe "inheritance" do
    it "inherits from ProgrammeTypeStep" do
      expect(subject).to be_a(Schools::RegisterECTWizard::ProgrammeTypeStep)
    end
  end

  describe "#next_step" do
    before { subject.send(:persist) }

    context 'when the ect programme type has changed from school led to provider led' do
      let(:programme_type) { 'school_led' }
      let(:new_programme_type) { 'provider_led' }

      it "returns :lead_provider" do
        expect(subject.next_step).to eq(:lead_provider)
      end
    end

    context 'when the ect programme type was and still is provider led' do
      let(:programme_type) { 'provider_led' }
      let(:new_programme_type) { 'provider_led' }

      it "returns :check_answers" do
        expect(subject.next_step).to eq(:check_answers)
      end
    end

    context 'when the ect programme type is school led' do
      let(:new_programme_type) { 'school_led' }

      it "returns :check_answers" do
        expect(subject.next_step).to eq(:check_answers)
      end
    end
  end

  describe "#previous_step" do
    it "returns :check_answers" do
      expect(subject.next_step).to eq(:check_answers)
    end
  end
end
