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
  let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, :ongoing, :with_school_partnership, mentor_at_school_period:, started_on: Time.zone.today) }

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

    context "when the lead_provider has not changed" do
      let(:params) { { lead_provider_id: training_period.active_lead_provider.lead_provider.id } }

      it "is invalid" do
        expect(current_step).to be_invalid
        expect(current_step.errors.messages_for(:lead_provider_id)).to contain_exactly(
          "Select a different lead provider to contact your school"
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
