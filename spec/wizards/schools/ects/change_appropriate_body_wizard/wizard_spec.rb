describe Schools::ECTs::ChangeAppropriateBodyWizard::Wizard do
  let(:wizard) do
    described_class.new(
      current_step: :check_answers,
      step_params: ActionController::Parameters.new,
      author:,
      store:,
      ect_at_school_period:
    )
  end

  let(:store) { FactoryBot.build(:session_repository) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:) }

  describe "#allowed_steps" do
    subject(:first_step) { wizard.allowed_steps }

    context "when the school is independent" do
      let(:school) { FactoryBot.create(:school, :independent) }

      it { is_expected.to eq(%i[independent_school check_answers confirmation]) }
    end

    context "when the school is not independent" do
      let(:school) { FactoryBot.create(:school, :state_funded) }

      it { is_expected.to eq(%i[state_school check_answers confirmation]) }
    end
  end
end
