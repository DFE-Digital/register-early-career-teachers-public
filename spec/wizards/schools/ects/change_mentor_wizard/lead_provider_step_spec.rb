describe Schools::ECTs::ChangeMentorWizard::LeadProviderStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ECTs::ChangeMentorWizard::Wizard.new(
      current_step: :lead_provider,
      step_params: ActionController::Parameters.new(lead_provider: params),
      author:,
      store:,
      ect_at_school_period:
    )
  end
  let(:store) do
    FactoryBot.build(
      :session_repository,
      mentor_at_school_period_id: mentor_at_school_period.id,
      accepting_current_lead_provider: nil
    )
  end
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school) }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, school:) }
  let(:mentor_at_school_period) do
    FactoryBot.create(
      :mentor_at_school_period,
      :ongoing,
      school:,
      started_on: ect_at_school_period.started_on - 1.month
    )
  end
  let(:params) { { lead_provider_id: "" } }

  describe ".permitted_params" do
    it "returns the permitted parameters" do
      expect(described_class.permitted_params)
        .to contain_exactly(:lead_provider_id)
    end
  end

  describe "#previous_step" do
    it "returns the edit step" do
      expect(current_step.previous_step).to eq(:training)
    end
  end

  describe "#next_step" do
    it "returns the check answers step" do
      expect(current_step.next_step).to eq(:check_answers)
    end
  end

  describe "#new_mentor_name" do
    it "returns the teacher's name from the selected mentor_at_school_period" do
      expect(current_step.new_mentor_name)
        .to eq(Teachers::Name.new(mentor_at_school_period.teacher).full_name)
    end
  end

  describe "validations" do
    context "when the lead_provider_id is blank" do
      let(:params) { { lead_provider_id: "" } }

      it "is invalid" do
        expect(current_step).to be_invalid
        expect(current_step.errors.messages_for(:lead_provider_id))
          .to contain_exactly("Select which lead provider will be training the ECT")
      end
    end

    context "when the lead_provider_id is invalid" do
      let(:params) { { lead_provider_id: "invalid" } }

      it "is invalid" do
        expect(current_step).to be_invalid
        expect(current_step.errors.messages_for(:lead_provider_id))
          .to contain_exactly("Enter the name of a known lead provider")
      end
    end

    context "when the lead_provider_id is valid" do
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:params) { { lead_provider_id: lead_provider.id } }

      it "is valid" do
        expect(current_step).to be_valid
        expect(current_step.errors).to be_empty
      end
    end
  end

  describe "#save!" do
    context "when the step is invalid" do
      let(:params) { { lead_provider_id: "" } }

      it "does not store the lead provider" do
        expect { current_step.save! }.not_to(change(store, :lead_provider_id))
      end

      it "is falsey" do
        expect(current_step.save!).to be_falsey
      end
    end

    context "when the lead_provider_id is valid" do
      let(:lead_provider) { FactoryBot.create(:lead_provider) }
      let(:params) { { lead_provider_id: lead_provider.id } }

      it "stores the lead provider" do
        expect { current_step.save! }
          .to(change(store, :lead_provider_id)
          .from(nil).to(lead_provider.id.to_s))
      end

      it "is truthy" do
        expect(current_step.save!).to be_truthy
      end
    end
  end
end
