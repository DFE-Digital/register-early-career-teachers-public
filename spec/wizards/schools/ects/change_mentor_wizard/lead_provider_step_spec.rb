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
      :unfinished,
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
    let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :unfinished, school:) }
    let!(:current_contract_period) { FactoryBot.create(:contract_period, :current) }
    let(:ect_lead_provider_contract_period) { current_contract_period }

    before do
      framework_agreement = FactoryBot.create(:framework_agreement, contract_period: ect_lead_provider_contract_period)
      school_partnership = FactoryBot.create(
        :school_partnership,
        school:,
        lead_provider_delivery_partnership: FactoryBot.create(:lead_provider_delivery_partnership, framework_agreement:)
      )

      FactoryBot.create(:training_period, :unfinished, :provider_led, ect_at_school_period:, school_partnership:)
    end

    it "returns the review_mentor_eligibility step" do
      expect(current_step.previous_step).to eq(:review_mentor_eligibility)
    end

    context "when the ECT's lead provider is not active in the current contract period" do
      let(:ect_lead_provider_contract_period) { FactoryBot.create(:contract_period, :previous) }

      it "returns the edit step" do
        expect(current_step.previous_step).to eq(:edit)
      end
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
    subject(:lead_providers_for_select) { current_step.lead_providers_for_select }

    let!(:current_contract_period) do
      FactoryBot.create(:contract_period, :current)
    end
    let(:upcoming_contract_period) do
      FactoryBot.create(:contract_period, :next)
    end
    let(:framework_agreement_contract_period) { current_contract_period }
    let!(:framework_agreement) do
      FactoryBot.create(:framework_agreement, contract_period: framework_agreement_contract_period)
    end
    let!(:other_lead_provider) do
      FactoryBot.create(:framework_agreement, contract_period: framework_agreement_contract_period)
    end
    let!(:future_lead_provider) do
      FactoryBot.create(:framework_agreement, contract_period: upcoming_contract_period)
    end
    let(:mentor_at_school_period) do
      FactoryBot.create(:mentor_at_school_period, school:, started_on:)
    end
    let(:started_on) { current_contract_period.started_on.next_month }

    it "offers the lead providers with a framework agreement for the current contract period" do
      expect(lead_providers_for_select)
        .to contain_exactly(framework_agreement.lead_provider, other_lead_provider.lead_provider)
    end

    context "when no lead provider has a framework agreement for the current contract period" do
      let(:framework_agreement_contract_period) { upcoming_contract_period }

      it { is_expected.to be_empty }
    end

    context "when the mentor started before the current contract period" do
      let(:started_on) { current_contract_period.started_on.prev_day }

      it "still offers the lead providers for the current contract period" do
        expect(lead_providers_for_select)
          .to contain_exactly(framework_agreement.lead_provider, other_lead_provider.lead_provider)
      end
    end
  end
end
