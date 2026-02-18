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
    it "returns the review_mentor_eligibility step" do
      expect(current_step.previous_step).to eq(:review_mentor_eligibility)
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

  describe "#lead_providers_for_select" do
    let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, :for_year, year: 2025) }
    let!(:other_lead_provider) { FactoryBot.create(:active_lead_provider, :for_year, year: 2025) }
    let!(:future_lead_provider) { FactoryBot.create(:active_lead_provider, :for_year, year: 2026) }
    let(:mentor_at_school_period) do
      FactoryBot.create(
        :mentor_at_school_period,
        :ongoing,
        school:,
        started_on:
      )
    end

    context "when there are no active lead providers in contract period containing the mentor's start date" do
      let(:started_on) { Date.new(2024, 6, 1) }

      it "returns an empty array" do
        expect(current_step.lead_providers_for_select).to be_empty
      end
    end

    context "when there are active lead providers in contract period containing the mentor's start date" do
      let(:started_on) { Date.new(2025, 6, 1) }

      it "returns the active lead providers in the contract period" do
        expect(current_step.lead_providers_for_select).to contain_exactly(active_lead_provider.lead_provider, other_lead_provider.lead_provider)
      end

      context "when the mentor started on the last day of the contract period" do
        let(:started_on) { Date.new(2026, 5, 31) }

        it "returns the active lead providers in the contract period" do
          expect(current_step.lead_providers_for_select).to contain_exactly(active_lead_provider.lead_provider, other_lead_provider.lead_provider)
        end
      end
    end
  end
end
