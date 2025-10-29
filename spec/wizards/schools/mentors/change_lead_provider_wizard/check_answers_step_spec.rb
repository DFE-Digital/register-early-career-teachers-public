describe Schools::Mentors::ChangeLeadProviderWizard::CheckAnswersStep, type: :model do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::Mentors::ChangeLeadProviderWizard::Wizard.new(
      current_step: :check_answers,
      step_params: ActionController::Parameters.new(check_answers: params),
      author:,
      store:,
      mentor_at_school_period:
    )
  end

  let(:store) do
    FactoryBot.build(:session_repository, lead_provider_id: lead_provider.id)
  end
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }

  let(:params) { { lead_provider_id: lead_provider.id } }

  let(:started_on) { 3.months.ago.to_date }
  let(:school) { FactoryBot.create(:school) }
  let!(:school_partnership) { FactoryBot.create(:school_partnership, school:) }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:mentor_at_school_period) do
    FactoryBot.create(
      :mentor_at_school_period,
      :ongoing,
      teacher:,
      school:,
      email: "mentor@example.com"
    )
  end

  let!(:contract_period) { FactoryBot.create(:contract_period, :current) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, contract_period:) }

  let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, :ongoing, mentor_at_school_period:, started_on:) }
  let(:old_lead_provider) { training_period.lead_provider }

  describe "#previous_step" do
    it "returns the previous step" do
      expect(current_step.previous_step).to eq(:edit)
    end
  end

  describe "#next_step" do
    it "returns the next step" do
      expect(current_step.next_step).to eq(:confirmation)
    end
  end

  describe "save!" do
    let(:service) { instance_double(MentorAtSchoolPeriods::ChangeLeadProvider) }

    before do
      allow(MentorAtSchoolPeriods::ChangeLeadProvider)
        .to receive(:new)
        .and_return(service)

      allow(service).to receive(:call).and_return(true)
    end

    it "calls the ChangeLeadProvider service" do
      current_step.save!

      expect(MentorAtSchoolPeriods::ChangeLeadProvider)
        .to have_received(:new)
        .with(
          mentor_at_school_period:,
          lead_provider:,
          author: wizard.author
        )

      expect(service).to have_received(:call)
    end

    it "records an event" do
      freeze_time

      expect(Events::Record)
        .to receive(:record_mentor_lead_provider_updated_event!)
        .with(
          old_lead_provider_name: old_lead_provider.name,
          new_lead_provider_name: lead_provider.name,
          author:,
          mentor_at_school_period:,
          school:,
          teacher: mentor_at_school_period.teacher,
          happened_at: Time.current
        )

      current_step.save!
    end

    it "is truthy" do
      expect(current_step.save!).to be_truthy
    end
  end
end
