describe Schools::ECTs::ChangeMentorWizard::CheckAnswersStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ECTs::ChangeMentorWizard::Wizard.new(
      current_step: :check_answers,
      step_params: ActionController::Parameters.new(check_answers: params),
      author:,
      store:,
      ect_at_school_period:
    )
  end
  let(:store) do
    FactoryBot.build(
      :session_repository,
      mentor_at_school_period_id: mentor_at_school_period.id,
      accepting_current_lead_provider:
    )
  end
  let(:author) { FactoryBot.build(:school_user, school_urn: school.urn) }
  let(:school) { FactoryBot.create(:school) }
  let(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      :ongoing,
      school:,
      started_on: 1.week.ago
    )
  end
  let(:mentor_at_school_period) do
    FactoryBot.create(
      :mentor_at_school_period,
      :ongoing,
      school:,
      started_on: ect_at_school_period.started_on - 1.month
    )
  end
  let(:accepting_current_lead_provider) { nil }
  let(:params) { {} }

  describe "#previous_step" do
    context "when the mentor is not eligible for training" do
      before do
        allow(::MentorAtSchoolPeriods::Eligibility)
          .to receive(:for_first_provider_led_training?)
          .and_return(false)
      end

      it "returns the edit step" do
        expect(current_step.previous_step).to eq(:edit)
      end
    end

    context "when the mentor is eligible for training" do
      before do
        allow(::MentorAtSchoolPeriods::Eligibility)
          .to receive(:for_first_provider_led_training?)
          .and_return(true)
      end

      context "when the current lead provider has been accepted" do
        let(:accepting_current_lead_provider) { true }

        it "returns the training step" do
          expect(current_step.previous_step).to eq(:training)
        end
      end

      context "when the current lead provider has not been accepted" do
        it "returns the lead provider step" do
          expect(current_step.previous_step).to eq(:lead_provider)
        end
      end
    end
  end

  describe "#next_step" do
    it "returns the check answers step" do
      expect(current_step.next_step).to eq(:confirmation)
    end
  end

  describe "#current_mentor_name" do
    let(:current_mentor_at_school_period) do
      FactoryBot.create(
        :mentor_at_school_period,
        :ongoing,
        school:,
        started_on: ect_at_school_period.started_on - 2.months
      )
    end
    let!(:mentorship_period) do
      FactoryBot.create(
        :mentorship_period,
        :ongoing,
        mentee: ect_at_school_period,
        mentor: current_mentor_at_school_period,
        started_on: ect_at_school_period.started_on
      )
    end

    it "returns the teacher's name from the current mentor_at_school_period" do
      expect(current_step.current_mentor_name)
        .to eq(Teachers::Name.new(current_mentor_at_school_period.teacher).full_name)
    end
  end

  describe "#new_mentor_name" do
    it "returns the teacher's name from the selected mentor_at_school_period" do
      expect(current_step.new_mentor_name)
        .to eq(Teachers::Name.new(mentor_at_school_period.teacher).full_name)
    end
  end

  describe "#save!" do
    let(:current_mentor_at_school_period) do
      FactoryBot.create(
        :mentor_at_school_period,
        :ongoing,
        school:,
        started_on: ect_at_school_period.started_on - 2.months
      )
    end
    let!(:mentorship_period) do
      FactoryBot.create(
        :mentorship_period,
        :ongoing,
        mentee: ect_at_school_period,
        mentor: current_mentor_at_school_period,
        started_on: ect_at_school_period.started_on
      )
    end

    it "assigns the mentor" do
      expect { current_step.save! }.to change(MentorshipPeriod, :count).by(1)
      expect(ect_at_school_period.reload.current_or_next_mentorship_period.mentor)
        .to eq(mentor_at_school_period)
    end

    it "is truthy" do
      expect(current_step.save!).to be_truthy
    end
  end
end
