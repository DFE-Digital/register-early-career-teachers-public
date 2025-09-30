describe Schools::ECTs::ChangeTrainingProgrammeWizard::ConfirmationStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ECTs::ChangeTrainingProgrammeWizard::Wizard.new(
      current_step: :confirmation,
      step_params: ActionController::Parameters.new(confirmation: params),
      author:,
      store:,
      ect_at_school_period:
    )
  end
  let(:store) { FactoryBot.build(:session_repository, training_programme: "provider_led") }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, school:) }
  let(:params) { {} }

  describe "#previous_step" do
    it "returns the check_answers step" do
      expect(current_step.previous_step).to eq(:check_answers)
    end
  end

  describe "#next_step" do
    it "raises an error" do
      expect { current_step.next_step }.to raise_error(NotImplementedError)
    end
  end

  describe "#new_training_programme" do
    it "returns the stored training programme" do
      expect(current_step.new_training_programme).to eq(store.training_programme)
    end
  end

  describe "#provider_name" do
    context "when there is no lead provider" do
      it "returns nil" do
        expect(current_step.provider_name).to be_nil
      end
    end

    context "when there is a confirmed school partnership" do
      let!(:training_period) do
        FactoryBot.create(
          :training_period,
          :ongoing,
          :for_ect,
          :with_school_partnership,
          ect_at_school_period:,
          started_on: ect_at_school_period.started_on
        )
      end

      it "returns the name of the lead provider" do
        expect(current_step.provider_name)
          .to eq(training_period.lead_provider.name)
      end
    end

    context "when there is an expression of interest" do
      let!(:training_period) do
        FactoryBot.create(
          :training_period,
          :ongoing,
          :for_ect,
          :with_only_expression_of_interest,
          ect_at_school_period:,
          started_on: ect_at_school_period.started_on
        )
      end

      it "returns the name of the lead provider from the expression of interest" do
        expect(current_step.provider_name)
          .to eq(training_period.expression_of_interest.lead_provider.name)
      end
    end
  end
end
