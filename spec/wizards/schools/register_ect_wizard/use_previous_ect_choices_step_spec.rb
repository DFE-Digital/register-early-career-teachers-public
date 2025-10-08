RSpec.describe Schools::RegisterECTWizard::UsePreviousECTChoicesStep, type: :model do
  subject { wizard.current_step }

  let(:use_previous_ect_choices) { true }
  let(:step_params) { {} }
  let(:school) { FactoryBot.create(:school) }
  let(:store) { FactoryBot.build(:session_repository, use_previous_ect_choices:) }
  let(:wizard) do
    FactoryBot.build(:register_ect_wizard,
                     current_step: :use_previous_ect_choices,
                     school:,
                     store:,
                     step_params:)
  end

  describe "#initialize" do
    subject { described_class.new(wizard:, **params) }

    context "when use_previous_ect_choices is provided" do
      let(:params) { { use_previous_ect_choices: false } }

      it { expect(subject.use_previous_ect_choices).to be(false) }
    end

    context "when no use_previous_ect_choices is provided" do
      let(:params) { {} }

      it { expect(subject.use_previous_ect_choices).to be(true) }
    end
  end

  describe "#next_step" do
    context "when use_previous_ect_choices is true" do
      let(:use_previous_ect_choices) { true }

      it { expect(subject.next_step).to eq(:check_answers) }
    end

    context "when use_previous_ect_choices is false" do
      let(:use_previous_ect_choices) { false }

      context "for independent schools" do
        let(:school) { FactoryBot.create(:school, :independent) }

        it { expect(subject.next_step).to eq(:independent_school_appropriate_body) }
      end

      context "for state-funded schools" do
        let(:school) { FactoryBot.create(:school, :state_funded) }

        it { expect(subject.next_step).to eq(:state_school_appropriate_body) }
      end
    end
  end

  describe "#previous_step" do
    it { expect(subject.previous_step).to eq(:working_pattern) }
  end

  describe "#save!" do
    let(:step_params) do
      ActionController::Parameters.new(
        "use_previous_ect_choices" => { "use_previous_ect_choices" => "0" }
      )
    end

    it "updates the wizard ect use_previous_ect_choices" do
      expect { subject.save! }
        .to change(subject.ect, :use_previous_ect_choices).from(true).to(false)
    end
  end
end
