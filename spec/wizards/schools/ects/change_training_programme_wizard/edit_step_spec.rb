describe Schools::ECTs::ChangeTrainingProgrammeWizard::EditStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ECTs::ChangeTrainingProgrammeWizard::Wizard.new(
      current_step: :edit,
      step_params: ActionController::Parameters.new(edit: params),
      author:,
      store:,
      ect_at_school_period:
    )
  end
  let(:store) { FactoryBot.build(:session_repository) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:) }
  let(:params) { {training_programme: ""} }

  describe ".permitted_params" do
    it "returns the permitted parameters" do
      expect(described_class.permitted_params).to contain_exactly(:training_programme)
    end
  end

  describe "#previous_step" do
    it "raises an error" do
      expect { current_step.previous_step }.to raise_error(NotImplementedError)
    end
  end

  describe "#next_step" do
    context "when the training programme is provider_led" do
      let(:params) { {training_programme: "provider_led"} }

      it "returns the lead provider step" do
        expect(current_step.next_step).to eq(:lead_provider)
      end
    end

    context "when the training programme is school_led" do
      let(:params) { {training_programme: "school_led"} }

      it "returns the check answers step" do
        expect(current_step.next_step).to eq(:check_answers)
      end
    end
  end

  describe "validations" do
    context "when training programme is blank" do
      let(:params) { {training_programme: nil} }

      it "is invalid" do
        expect(current_step).not_to be_valid
        expect(current_step.errors.messages_for(:training_programme))
          .to contain_exactly("Select either 'Provider-led' or 'School-led' training")
      end
    end

    context "when training programme is invalid" do
      let(:params) { {training_programme: "something-invalid"} }

      it "is invalid" do
        expect(current_step).not_to be_valid
        expect(current_step.errors.messages_for(:training_programme))
          .to contain_exactly("'something-invalid' is not a valid training programme")
      end
    end

    context "when training programme is valid" do
      let(:params) { {training_programme: "provider_led"} }

      it "is valid" do
        expect(current_step).to be_valid
        expect(current_step.errors).to be_empty
      end
    end
  end

  describe "#save!" do
    context "when the training programme is valid" do
      let(:params) { {training_programme: "provider_led"} }

      it "stores the training programme" do
        expect { current_step.save! }
          .to change(store, :training_programme)
          .from(nil).to("provider_led")
      end

      it "is truthy" do
        expect(current_step.save!).to be_truthy
      end
    end

    context "when the training programme is invalid" do
      let(:params) { {training_programme: ""} }

      it "does not store the training programme" do
        expect { current_step.save! }
          .not_to change(store, :training_programme)
      end

      it "is falsey" do
        expect(current_step.save!).to be_falsey
      end
    end
  end
end
