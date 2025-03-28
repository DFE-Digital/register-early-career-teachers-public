RSpec.describe Schools::RegisterECTWizard::ChangeLeadProviderStep, type: :model do
  subject { described_class.new(wizard:, lead_provider_id:) }

  let(:lead_provider_id) { '1' }
  let(:school) { FactoryBot.create(:school, :independent) }
  let(:wizard) do
    FactoryBot.build(:register_ect_wizard, current_step: :change_lead_provider, school:)
  end

  describe "inheritance" do
    it "inherits from LeadProviderStep" do
      expect(subject).to be_a(Schools::RegisterECTWizard::LeadProviderStep)
    end
  end

  describe "#next_step" do
    it { expect(subject.next_step).to eq(:check_answers) }
  end

  describe "#previous_step" do
    context 'when the school has programme choices' do
      let(:school) { FactoryBot.create(:school, :independent, :teaching_school_hub_ab_chosen, :provider_led_chosen) }

      it { expect(subject.previous_step).to eq(:change_programme_type) }
    end

    context 'when the ect has no lead provider set' do
      it { expect(subject.previous_step).to eq(:change_programme_type) }
    end

    context 'when the school has no programme choices and the ect has a lead provider set' do
      let(:lead_provider_id) { FactoryBot.create(:lead_provider).id }

      before { subject.send(:persist) }

      it { expect(subject.previous_step).to eq(:check_answers) }
    end
  end
end
