describe Schools::ECTs::ChangeLeadProviderWizard::EditStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ECTs::ChangeLeadProviderWizard::Wizard.new(
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
  let(:params) { { lead_provider_id: "" } }

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
    it "returns the check answers step" do
      expect(current_step.next_step).to eq(:check_answers)
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

    let(:current_contract_period) do
      FactoryBot.create(:contract_period, :current)
    end
    let(:upcoming_contract_period) do
      FactoryBot.create(:contract_period, :next)
    end
    let!(:active_lead_provider) do
      FactoryBot.create(:active_lead_provider, contract_period: current_contract_period)
    end
    let!(:other_lead_provider) do
      FactoryBot.create(:active_lead_provider, contract_period: current_contract_period)
    end
    let!(:future_lead_provider) do
      FactoryBot.create(:active_lead_provider, contract_period: upcoming_contract_period)
    end
    let(:ect_at_school_period) do
      FactoryBot.create(:ect_at_school_period, :ongoing, school:, started_on:)
    end
    let!(:training_period) do
      FactoryBot.create(
        :training_period,
        :for_ect,
        :ongoing,
        :provider_led,
        ect_at_school_period:,
        started_on: ect_at_school_period.started_on
      )
    end

    context "when there are no active lead providers in contract period containing the ect's start date" do
      let(:started_on) { current_contract_period.started_on.prev_day }

      it { is_expected.to be_empty }
    end

    context "when there are active lead providers in contract period containing the ect's start date" do
      let(:started_on) { current_contract_period.started_on.next_month }

      it { is_expected.to contain_exactly(active_lead_provider.lead_provider, other_lead_provider.lead_provider) }

      context "when the ect starts on the last day of the contract period" do
        let(:started_on) { current_contract_period.finished_on }

        it { is_expected.to contain_exactly(active_lead_provider.lead_provider, other_lead_provider.lead_provider) }
      end
    end

    context "when the ECT started provider-led training in a frozen contract period" do
      let(:started_on) { frozen_contract_period.started_on.next_week }

      let(:frozen_contract_period) do
        FactoryBot.create(
          :contract_period,
          :with_payments_frozen,
          year: 2021
        )
      end
      let(:school_partnership) do
        FactoryBot.create(:school_partnership, :for_year, year: 2021, school:)
      end
      let!(:training_period) do
        FactoryBot.create(
          :training_period,
          :for_ect,
          :provider_led,
          ect_at_school_period:,
          started_on: ect_at_school_period.started_on,
          school_partnership:
        )
      end

      let!(:replacement_active_lead_provider) do
        FactoryBot.create(:active_lead_provider, :for_year, year: 2024)
      end

      it { is_expected.to contain_exactly(replacement_active_lead_provider.lead_provider) }
    end
  end
end
