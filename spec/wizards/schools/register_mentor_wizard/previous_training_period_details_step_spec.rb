RSpec.describe Schools::RegisterMentorWizard::PreviousTrainingPeriodDetailsStep, type: :model do
  subject { wizard.current_step }

  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing) }
  let(:store) { FactoryBot.build(:session_repository) }
  let(:author) { FactoryBot.create(:school_user, school_urn: ect_at_school_period.school.urn) }
  let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :previous_training_period_details, store:, author:, ect_id: ect_at_school_period.id) }

  describe "#next_step" do
    context "when ect lead provider is invalid and mentor has no lead provider set" do
      before do
        allow(wizard.mentor).to receive_messages(
          ect_lead_provider_invalid?: true,
          lead_provider: nil
        )
      end

      it { expect(subject.next_step).to eq(:lead_provider) }
    end

    context "when ect lead provider is valid" do
      before { allow(wizard.mentor).to receive(:ect_lead_provider_invalid?).and_return(false) }

      it { expect(subject.next_step).to eq(:programme_choices) }
    end
  end

  describe "#previous_step" do
    it { expect(subject.previous_step).to eq(:started_on) }
  end
end
