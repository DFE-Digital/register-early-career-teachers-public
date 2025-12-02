RSpec.describe Schools::AssignExistingMentorWizard::LeadProviderStep do
  subject(:step) { described_class.new(wizard:, lead_provider_id:) }

  include_context "safe_schedules"
  include ActiveJob::TestHelper

  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:lead_provider_id) { lead_provider.id }
  let(:school) { FactoryBot.create(:school) }
  let(:started_on) { mid_year - 2.days }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, school:, started_on:) }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:, started_on:) }
  let(:user) { FactoryBot.create(:user) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }

  let(:context) do
    instance_double(
      Schools::Shared::MentorAssignmentContext,
      ect_at_school_period:,
      mentor_at_school_period:
    )
  end

  let(:wizard) do
    instance_double(
      Schools::AssignExistingMentorWizard::Wizard,
      context:,
      author:
    )
  end

  describe "#valid?" do
    context "when lead_provider_id is nil" do
      let(:lead_provider_id) { nil }

      it "is invalid with correct error" do
        expect(step).not_to be_valid
        expect(step.errors[:lead_provider_id]).to include("Select a lead provider to contact your school")
      end
    end

    context "when lead_provider_id is present" do
      it "is valid" do
        expect(step).to be_valid
      end
    end
  end

  describe "#next_step" do
    it { expect(step.next_step).to eq(:confirmation) }
  end

  describe "#previous_step" do
    it { expect(step.previous_step).to eq(:review_mentor_eligibility) }
  end

  describe "#save" do
    let(:store) { OpenStruct.new(lead_provider_id: nil) }
    let(:contract_period) { FactoryBot.create(:contract_period, :with_schedules, :current) }
    let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }

    let(:wizard) do
      instance_double(
        Schools::AssignExistingMentorWizard::Wizard,
        context:,
        author:,
        store:,
        valid_step?: true
      )
    end

    around do |example|
      perform_enqueued_jobs { example.run }
    end

    it "persists the selected lead_provider_id to the store" do
      expect { step.save! }.to change(store, :lead_provider_id).from(nil).to(lead_provider_id)
    end

    it "assigns the mentor to the ECT" do
      expect { step.save! }.to change { mentor_at_school_period.reload.mentorship_periods.count }.from(0).to(1)

      mentorship_period = mentor_at_school_period.mentorship_periods.last
      expect(mentorship_period.mentee).to eq(ect_at_school_period)
    end

    it "creates a training period for the mentor" do
      expect { step.save! }.to change { mentor_at_school_period.reload.training_periods.count }.from(0).to(1)

      training_period = mentor_at_school_period.training_periods.last
      expect(training_period).to have_attributes(
        started_on:,
        training_programme: "provider_led"
      )
    end

    it "records training and mentoring events" do
      step.save!

      events = Event.where(teacher: [mentor_at_school_period.teacher, ect_at_school_period.teacher])
      expect(events.pluck(:event_type)).to contain_exactly(
        "teacher_schedule_assigned_to_training_period",
        "teacher_starts_training_period",
        "teacher_starts_mentoring",
        "teacher_starts_being_mentored"
      )
    end

    context "when the mentee has previously started training with another mentor" do
      let(:previous_mentor) { FactoryBot.create(:mentor_at_school_period, started_on:, finished_on: 1.day.ago) }
      let(:previous_mentor_training_period) { FactoryBot.create(:training_period, :provider_led, :ongoing, :for_mentor, started_on:, mentor_at_school_period: previous_mentor) }
      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:, started_on: Date.current) }

      before do
        FactoryBot.create(:schedule, contract_period:, identifier: "ecf-replacement-january")
        FactoryBot.create(:schedule, contract_period:, identifier: "ecf-replacement-april")
        FactoryBot.create(:schedule, contract_period:, identifier: "ecf-replacement-september")

        FactoryBot.create(:training_period,
                          :ongoing,
                          :provider_led,
                          :with_no_school_partnership,
                          ect_at_school_period:,
                          started_on:,
                          expression_of_interest: active_lead_provider)

        FactoryBot.create(:mentorship_period,
                          started_on:,
                          finished_on: 1.day.ago,
                          mentee: ect_at_school_period,
                          mentor: previous_mentor)

        FactoryBot.create(:declaration, training_period: previous_mentor_training_period)
      end

      it "assigns a replacement schedule to the mentor training period" do
        step.save!

        training_period = mentor_at_school_period.training_periods.last
        expect(training_period.schedule.identifier).to eq("ecf-replacement-september")
      end
    end
  end
end
