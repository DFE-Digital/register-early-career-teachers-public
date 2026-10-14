RSpec.describe Schools::AssignExistingMentorWizard::Operations::AssignMentorWithTraining do
  subject(:operation) { described_class.new(repository: state_store.repository, step: wizard.current_step) }

  include_context "safe_schedules"

  let(:wizard) do
    Schools::AssignExistingMentorWizard::Wizard.new(state_store:, current_step:, current_step_params:)
  end
  let(:state_store) { Schools::AssignExistingMentorWizard::StateStore.new }
  let(:current_step_params) { {} }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:school) { FactoryBot.create(:school) }
  let(:started_on) { mid_year - 2.days }
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :unfinished, school:, started_on:) }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :unfinished, school:, started_on:) }
  let(:user) { FactoryBot.create(:user) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:contract_period) { FactoryBot.create(:contract_period, :with_schedules, :current) }
  let!(:framework_agreement) { FactoryBot.create(:framework_agreement, lead_provider:, contract_period:) }

  before do
    state_store.write(ect_id: ect_at_school_period.id, mentor_period_id: mentor_at_school_period.id)
    allow(wizard).to receive(:author).and_return(author)
  end

  def create_replacement_schedules
    %w[ecf-replacement-january ecf-replacement-april ecf-replacement-september].each do |identifier|
      FactoryBot.create(:schedule, contract_period:, identifier:)
    end
  end

  shared_examples "assigns the mentor and starts their training" do
    it "succeeds" do
      expect(operation.execute).to eq(success: true)
    end

    it "assigns the mentor to the ECT" do
      expect { operation.execute }.to change { mentor_at_school_period.reload.mentorship_periods.count }.from(0).to(1)

      expect(mentor_at_school_period.mentorship_periods.last.mentee).to eq(ect_at_school_period)
    end

    it "creates a provider-led training period for the mentor" do
      expect { operation.execute }.to change { mentor_at_school_period.reload.training_periods.count }.from(0).to(1)

      expect(mentor_at_school_period.training_periods.last).to have_attributes(
        started_on:,
        training_programme: "provider_led"
      )
    end

    it "sets the mentors funding eligibility" do
      expect { operation.execute }
        .to change { mentor_at_school_period.teacher.reload.mentor_first_became_eligible_for_training_at }
        .from(nil).to(Time.zone.now)
    end

    it "records training and mentoring events" do
      operation.execute

      events = Event.where(teacher: [mentor_at_school_period.teacher, ect_at_school_period.teacher])
      expect(events.pluck(:event_type)).to contain_exactly(
        "teacher_schedule_assigned_to_training_period",
        "teacher_funding_eligibility_set",
        "teacher_starts_training_period",
        "teacher_starts_mentoring",
        "teacher_starts_being_mentored"
      )
    end
  end

  context "when the ECTs lead provider is confirmed on the review mentor eligibility step" do
    let(:current_step) { :review_mentor_eligibility }
    let(:school_partnership) do
      FactoryBot.create(
        :school_partnership,
        school:,
        lead_provider_delivery_partnership: FactoryBot.create(:lead_provider_delivery_partnership, framework_agreement:)
      )
    end

    before do
      FactoryBot.create(:training_period, :unfinished, :provider_led, ect_at_school_period:, started_on:, school_partnership:)
    end

    it_behaves_like "assigns the mentor and starts their training"

    it "trains the mentor with the ECTs school partnership on the standard schedule" do
      operation.execute

      training_period = mentor_at_school_period.training_periods.sole
      expect(training_period.school_partnership).to eq(school_partnership)
      expect(training_period.schedule.identifier).to eq("ecf-standard-september")
    end

    context "when the mentee has previously started training with another mentor" do
      let(:previous_mentor) do
        FactoryBot.create(:mentor_at_school_period, school:, started_on: 1.month.ago, finished_on: 1.day.ago)
      end
      let(:previous_mentor_training_period) do
        FactoryBot.create(
          :training_period,
          :provider_led,
          :for_mentor,
          started_on: 2.days.ago,
          finished_on: 1.day.ago,
          mentor_at_school_period: previous_mentor
        )
      end

      before do
        create_replacement_schedules

        FactoryBot.create(
          :mentorship_period,
          started_on: 2.days.ago,
          finished_on: 1.day.ago,
          mentee: ect_at_school_period,
          mentor: previous_mentor
        )
        FactoryBot.create(:declaration, :within_mentorship_period, training_period: previous_mentor_training_period)
      end

      it "assigns a replacement schedule to the mentor training period" do
        operation.execute

        expect(mentor_at_school_period.training_periods.last.schedule.identifier).to eq("ecf-replacement-september")
      end
    end
  end

  context "when a lead provider is selected on the lead provider step" do
    let(:current_step) { :lead_provider }
    let(:current_step_params) { { lead_provider: { lead_provider_id: lead_provider.id } } }

    it_behaves_like "assigns the mentor and starts their training"

    context "when the ECTs own lead provider is not active in the current contract period" do
      let(:ect_at_school_period) do
        FactoryBot.create(:ect_at_school_period, :unfinished, school:, started_on: mid_year - 1.year)
      end

      before do
        earlier_contract_period = FactoryBot.create(:contract_period, :previous, :with_schedules)
        earlier_framework_agreement = FactoryBot.create(:framework_agreement, contract_period: earlier_contract_period)
        school_partnership = FactoryBot.create(
          :school_partnership,
          school:,
          lead_provider_delivery_partnership: FactoryBot.create(
            :lead_provider_delivery_partnership,
            framework_agreement: earlier_framework_agreement
          )
        )

        FactoryBot.create(
          :training_period,
          :unfinished,
          :provider_led,
          ect_at_school_period:,
          started_on: ect_at_school_period.started_on,
          school_partnership:
        )
      end

      it "creates the mentor training period against the chosen lead provider" do
        expect { operation.execute }.to change { mentor_at_school_period.reload.training_periods.count }.from(0).to(1)

        expect(mentor_at_school_period.training_periods.sole.expression_of_interest).to eq(framework_agreement)
      end
    end

    context "when the mentee has previously started training with another mentor" do
      let(:previous_mentor) do
        FactoryBot.create(:mentor_at_school_period, school:, started_on:, finished_on: started_on + 2.months)
      end
      let(:previous_mentor_training_period) do
        FactoryBot.create(
          :training_period,
          :provider_led,
          :for_mentor,
          started_on:,
          finished_on: started_on + 2.months,
          mentor_at_school_period: previous_mentor
        )
      end
      let(:mentor_at_school_period) do
        FactoryBot.create(:mentor_at_school_period, :unfinished, school:, started_on: Date.current)
      end

      before do
        create_replacement_schedules

        FactoryBot.create(
          :training_period,
          :unfinished,
          :provider_led,
          :with_no_school_partnership,
          ect_at_school_period:,
          started_on:,
          expression_of_interest: framework_agreement
        )
        FactoryBot.create(
          :mentorship_period,
          started_on:,
          finished_on: started_on + 2.months,
          mentee: ect_at_school_period,
          mentor: previous_mentor
        )
        FactoryBot.create(:declaration, :within_mentorship_period, training_period: previous_mentor_training_period)
      end

      it "assigns a replacement schedule to the mentor training period" do
        operation.execute

        expect(mentor_at_school_period.training_periods.last.schedule.identifier).to eq("ecf-replacement-september")
      end
    end
  end
end
