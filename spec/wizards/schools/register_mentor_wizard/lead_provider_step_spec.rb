RSpec.describe Schools::RegisterMentorWizard::LeadProviderStep, type: :model do
  subject { wizard.current_step }

  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :unfinished) }
  let(:store) { FactoryBot.build(:session_repository) }
  let(:author) { FactoryBot.create(:school_user, school_urn: ect_at_school_period.school.urn) }
  let(:wizard) { FactoryBot.build(:register_mentor_wizard, current_step: :lead_provider, store:, author:, ect_id: ect_at_school_period.id) }

  describe "steps" do
    describe "#next_step" do
      it { expect(subject.next_step).to eq(:check_answers) }
    end

    describe "#previous_step" do
      context "when the ect lead provider is invalid" do
        before { allow(wizard.mentor).to receive(:ect_lead_provider_invalid?).and_return(true) }

        context "and mentor has not been registered before" do
          before { allow(wizard.mentor).to receive(:previously_registered_as_mentor?).and_return(false) }

          it { expect(subject.previous_step).to eq(:email_address) }
        end

        context "and mentor has been registered before with a training period" do
          before do
            allow(wizard.mentor).to receive_messages(previously_registered_as_mentor?: true, previous_training_period: FactoryBot.build(:training_period))
          end

          it { expect(subject.previous_step).to eq(:previous_training_period_details) }
        end

        context "and mentor has been registered before without a training period" do
          before do
            allow(wizard.mentor).to receive_messages(previously_registered_as_mentor?: true, previous_training_period: nil)
          end

          it { expect(subject.previous_step).to eq(:started_on) }
        end
      end

      context "when the ect lead provider is valid" do
        before { allow(wizard.mentor).to receive(:ect_lead_provider_invalid?).and_return(false) }

        it { expect(subject.previous_step).to eq(:programme_choices) }
      end
    end
  end
end
