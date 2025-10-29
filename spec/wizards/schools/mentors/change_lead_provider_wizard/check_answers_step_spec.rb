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
  let(:school) { FactoryBot.create(:school) }
  let(:mentor_at_school_period) do
    FactoryBot.create(:mentor_at_school_period, school:)
  end
  let(:school_partnership) { FactoryBot.create(:school_partnership, school:) }
  let(:lead_provider) { school_partnership.lead_provider }
  let(:params) { { lead_provider_id: lead_provider.id } }

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

      allow(service).to receive(:call)
    end

    it "calls the ChangeLeadProvider service" do
      current_step.save!

      expect(MentorAtSchoolPeriods::ChangeLeadProvider)
        .to have_received(:new)
        .with(
          mentor_at_school_period:,
          school_partnership:,
          author: wizard.author
        )

      expect(service).to have_received(:call)
    end

    it "records an event", skip: 'EVENTS_TODO' do
      freeze_time

      expect(Events::Record)
        .to receive(:record_teacher_email_updated_event!)
        .with(
          old_email: "old@example.com",
          new_email: "new@example.com",
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
