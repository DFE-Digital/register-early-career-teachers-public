RSpec.describe Schools::AssignExistingMentorWizard::ReviewMentorEligibilityStep do
  subject(:step) { described_class.new(wizard:) }

  include_context "safe_schedules"
  include ActiveJob::TestHelper

  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:school) { FactoryBot.create(:school) }
  let(:started_on) { mid_year - 2.days }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, school:, started_on:) }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:, started_on:) }
  let(:user) { FactoryBot.create(:user) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }

  let(:context) do
    instance_double(Schools::Shared::MentorAssignmentContext,
                    ect_at_school_period:,
                    mentor_at_school_period:)
  end

  let(:wizard) do
    instance_double(
      Schools::AssignExistingMentorWizard::Wizard,
      context:,
      author:
    )
  end

  describe "#next_step" do
    it "returns :confirmation" do
      expect(step.next_step).to eq(:confirmation)
    end
  end

  describe "#save" do
    let(:store) { OpenStruct.new }

    let(:wizard) do
      instance_double(
        Schools::AssignExistingMentorWizard::Wizard,
        context:,
        author:,
        store:,
        valid_step?: true
      )
    end

    let(:contract_period) { FactoryBot.create(:contract_period, :with_schedules, :current) }

    around do |example|
      perform_enqueued_jobs { example.run }
    end

    before do
      active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:)

      school_partnership = FactoryBot.create(
        :school_partnership,
        school:,
        lead_provider_delivery_partnership: FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
      )
      FactoryBot.create(:training_period, :ongoing, :provider_led,
                        ect_at_school_period:,
                        started_on:,
                        school_partnership:)
    end

    it "assigns the mentor to the ECT" do
      expect { step.save! }.to change { mentor_at_school_period.reload.mentorship_periods.count }.from(0).to(1)

      mentorship_period = mentor_at_school_period.mentorship_periods.last
      expect(mentorship_period.mentee).to eq(ect_at_school_period)
    end

    it "creates a training period for the mentor using ECT current lead provider" do
      expect { step.save! }.to change { mentor_at_school_period.reload.training_periods.count }.from(0).to(1)

      training_period = mentor_at_school_period.training_periods.last
      expect(training_period).to have_attributes(
        started_on:,
        training_programme: "provider_led"
      )
      expect(training_period.schedule.identifier).to eq("ecf-standard-september")
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

    context "on the last day of the contract period" do
      let(:travel_date) { contract_period.finished_on }
      let(:started_on) { travel_date }

      it "assigns the mentor to the ECT" do
        expect { step.save! }.to change { mentor_at_school_period.reload.mentorship_periods.count }.from(0).to(1)

        mentorship_period = mentor_at_school_period.mentorship_periods.last
        expect(mentorship_period.mentee).to eq(ect_at_school_period)
      end
    end

    context "when the mentee has previously started training with another mentor" do
      let(:previous_mentor) { FactoryBot.create(:mentor_at_school_period, school: ect_at_school_period.school, started_on: 1.month.ago, finished_on: 1.day.ago) }
      let(:previous_mentor_training_period) { FactoryBot.create(:training_period, :provider_led, :ongoing, :for_mentor, started_on: 2.days.ago, mentor_at_school_period: previous_mentor) }

      before do
        FactoryBot.create(:schedule, contract_period:, identifier: "ecf-replacement-january")
        FactoryBot.create(:schedule, contract_period:, identifier: "ecf-replacement-april")
        FactoryBot.create(:schedule, contract_period:, identifier: "ecf-replacement-september")

        FactoryBot.create(:mentorship_period,
                          started_on: 2.days.ago,
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
