describe Schools::ECTs::ChangeLeadProviderWizard::CheckAnswersStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ECTs::ChangeLeadProviderWizard::Wizard.new(
      current_step: :check_answers,
      step_params: ActionController::Parameters.new(check_answers: params),
      author:,
      store:,
      ect_at_school_period:
    )
  end
  let(:store) do
    FactoryBot.build(:session_repository, lead_provider_id: lead_provider.id)
  end
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school) }
  let(:contract_period) do
    FactoryBot.create(:contract_period, :with_schedules, :current)
  end
  let(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      :ongoing,
      school:,
      started_on: contract_period.started_on + 1.week
    )
  end
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let!(:active_lead_provider) do
    FactoryBot.create(
      :active_lead_provider,
      lead_provider:,
      contract_period:
    )
  end
  let(:old_lead_provider) { FactoryBot.create(:lead_provider) }
  let(:current_active_lead_provider) do
    FactoryBot.create(
      :active_lead_provider,
      lead_provider: old_lead_provider,
      contract_period:
    )
  end
  let!(:training_period) do
    FactoryBot.create(
      :training_period,
      :ongoing,
      :provider_led,
      :with_only_expression_of_interest,
      ect_at_school_period:,
      started_on: ect_at_school_period.started_on,
      expression_of_interest: current_active_lead_provider
    )
  end
  let(:params) { {} }

  describe "#previous_step" do
    it "returns the edit step" do
      expect(current_step.previous_step).to eq(:edit)
    end
  end

  describe "#next_step" do
    it "returns the confirmation step" do
      expect(current_step.next_step).to eq(:confirmation)
    end
  end

  describe "#old_lead_provider_name" do
    it "returns the current lead provider's name" do
      expect(current_step.old_lead_provider_name)
        .to eq(old_lead_provider.name)
    end
  end

  describe "#new_lead_provider_name" do
    it "returns the selected lead provider's name" do
      expect(current_step.new_lead_provider_name).to eq(lead_provider.name)
    end
  end

  describe "#save!" do
    it "changes the lead provider" do
      expect { current_step.save! }
        .to change { lead_provider_for(ect_at_school_period) }
        .from(old_lead_provider)
        .to(lead_provider)
    end

    it "is truthy" do
      expect(current_step.save!).to be_truthy
    end

    context "when the new lead provider is the same as the old lead provider" do
      let(:old_lead_provider) { lead_provider }

      it "is falsy" do
        expect(current_step.save!).to be_falsey
      end
    end
  end

private

  def lead_provider_for(ect_at_school_period)
    ect_at_school_period.reload
      .current_or_next_training_period
      .expression_of_interest
      .lead_provider
  end
end
