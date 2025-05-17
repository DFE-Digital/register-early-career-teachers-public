RSpec.describe Schools::RegisterECTWizard::NoPreviousECTChoicesChangeLeadProviderStep, type: :model do
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
    it { expect(subject.previous_step).to eq(:no_previous_ect_choices_change_programme_type) }
  end
end
