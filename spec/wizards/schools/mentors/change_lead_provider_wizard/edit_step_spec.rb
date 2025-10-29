describe Schools::Mentors::ChangeLeadProviderWizard::EditStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::Mentors::ChangeLeadProviderWizard::Wizard.new(
      current_step: :edit,
      step_params: ActionController::Parameters.new(edit: params),
      author:,
      store:,
      mentor_at_school_period:
    )
  end
  let(:store) { FactoryBot.build(:session_repository) }
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school) }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:params) { { lead_provider_id: lead_provider.id } }

  describe ".permitted_params" do
    it "returns the permitted parameters" do
      expect(described_class.permitted_params).to contain_exactly(:lead_provider_id)
    end
  end

  describe "#previous_step" do
    it "raises an error" do
      expect { current_step.previous_step }.to raise_error(NotImplementedError)
    end
  end

  describe "#next_step" do
    it "returns the next step" do
      expect(current_step.next_step).to eq(:check_answers)
    end
  end

  describe "validations" do
    context "when lead_provider_id is blank" do
      let(:params) { { lead_provider_id: "" } }

      it "is invalid" do
        expect(current_step).to be_invalid
        expect(current_step.errors.messages_for(:lead_provider_id)).to contain_exactly(
          "Select a lead provider to contact your school"
        )
      end
    end

    context "when lead_provider_id is valid" do
      it "is valid" do
        expect(current_step).to be_valid
        expect(current_step.errors).to be_empty
      end
    end
  end

  describe "save!" do
    context "when lead_provider_id is invalid" do
      let(:params) { { lead_provider_id: "" } }

      it "does not store the lead_provider_id" do
        expect { current_step.save! }.not_to(change(store, :lead_provider_id))
      end

      it "is falsy" do
        expect(current_step.save!).to be_falsy
      end
    end

    context "when lead_provider_id is valid" do
      it "stores the lead_provider_id" do
        expect { current_step.save! }.to change(store, :lead_provider_id)
          .to(lead_provider.id.to_s)
      end

      it "is truthy" do
        expect(current_step.save!).to be_truthy
      end
    end
  end
end
