describe Schools::ECTs::ChangeMentorWizard::EditStep do
  subject(:current_step) { wizard.current_step }

  let(:wizard) do
    Schools::ECTs::ChangeMentorWizard::Wizard.new(
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
  let(:ect_at_school_period) do
    FactoryBot.create(:ect_at_school_period, :ongoing, school:)
  end
  let(:current_mentor_at_school_period) do
    FactoryBot.create(
      :mentor_at_school_period,
      :ongoing,
      school:,
      started_on: ect_at_school_period.started_on - 1.month
    )
  end
  let!(:current_mentorship_period) do
    FactoryBot.create(
      :mentorship_period,
      :ongoing,
      mentee: ect_at_school_period,
      mentor: current_mentor_at_school_period,
      started_on: ect_at_school_period.started_on + 1.week
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
  let(:params) { { mentor_at_school_period_id: "" } }

  describe ".permitted_params" do
    it "returns the permitted parameters" do
      expect(described_class.permitted_params).to contain_exactly(:mentor_at_school_period_id)
    end
  end

  describe "#previous_step" do
    it "raises an error" do
      expect { current_step.previous_step }.to raise_error(NotImplementedError)
    end
  end

  describe "#next_step" do
    before { store.mentor_at_school_period_id = mentor_at_school_period.id }

    context "when the mentor is eligible for training" do
      before do
        allow(::MentorAtSchoolPeriods::Eligibility)
          .to receive(:for_first_provider_led_training?)
          .and_return(true)
      end

      it "returns the review_mentor_eligibility step" do
        expect(current_step.next_step).to eq(:review_mentor_eligibility)
      end
    end

    context "when the mentor is not eligible for training" do
      before do
        allow(::MentorAtSchoolPeriods::Eligibility)
          .to receive(:for_first_provider_led_training?)
          .and_return(false)
      end

      it "returns the check answers step" do
        expect(current_step.next_step).to eq(:check_answers)
      end
    end
  end

  describe "validations" do
    context "when the mentor_at_school_period_id is blank" do
      let(:params) { { mentor_at_school_period_id: "" } }

      it "is invalid" do
        expect(current_step).not_to be_valid
        expect(current_step.errors.messages_for(:mentor_at_school_period_id))
          .to contain_exactly("Select a mentor from the list provided")
      end
    end

    context "when the mentor_at_school_period_id is not in the list" do
      let(:params) { { mentor_at_school_period_id: "invalid_id" } }

      it "is invalid" do
        expect(current_step).not_to be_valid
        expect(current_step.errors.messages_for(:mentor_at_school_period_id))
          .to contain_exactly("Select a mentor from the list provided")
      end
    end

    context "when the mentor_at_school_period_id is valid" do
      let(:params) { { mentor_at_school_period_id: mentor_at_school_period.id } }

      it "is valid" do
        expect(current_step).to be_valid
        expect(current_step.errors).to be_empty
      end
    end
  end

  describe "#save!" do
    context "when the mentor_at_school_period_id is valid" do
      let(:params) { { mentor_at_school_period_id: mentor_at_school_period.id } }

      it "stores the mentor_at_school_period_id" do
        expect { current_step.save! }
          .to change(store, :mentor_at_school_period_id)
          .from(nil).to(mentor_at_school_period.id.to_s)
      end

      it "is truthy" do
        expect(current_step.save!).to be_truthy
      end
    end

    context "when the mentor_at_school_period_id is invalid" do
      let(:params) { { mentor_at_school_period_id: "" } }

      it "does not store the mentor_at_school_period_id" do
        expect { current_step.save! }
          .not_to change(store, :mentor_at_school_period_id)
      end

      it "is falsy" do
        expect(current_step.save!).to be_falsy
      end
    end
  end

  describe "#mentors_for_select" do
    let(:envelope_start) { Date.new(2098, 1, 1) }
    let(:envelope_end)   { Date.new(2100, 12, 31) }

    let(:ect_at_school_period) do
      FactoryBot.create(
        :ect_at_school_period,
        school:,
        started_on: envelope_start,
        finished_on: envelope_end
      )
    end

    context "when there is no current mentorship period" do
      let!(:current_mentorship_period) { nil }

      # Two ongoing mentors at the same school -> both are eligible
      let!(:mentor_at_school_period_1) do
        FactoryBot.create(:mentor_at_school_period, :ongoing, school:, started_on: envelope_start)
      end

      let!(:mentor_at_school_period_2) do
        FactoryBot.create(:mentor_at_school_period, :ongoing, school:, started_on: envelope_start)
      end

      it "returns all eligible mentors" do
        expect(current_step.mentors_for_select.ids).to contain_exactly(mentor_at_school_period_1.id, mentor_at_school_period_2.id)
      end
    end

    context "when there is a current mentorship period (current mentor not eligible)" do
      let!(:mentor_at_school_period_1) { FactoryBot.create(:mentor_at_school_period, :ongoing, school:, started_on: envelope_start) }

      # mentor 2 is the current mentor but is (not ongoing) -> not eligible
      let!(:mentor_at_school_period_2) { FactoryBot.create(:mentor_at_school_period, school:, started_on: envelope_start, finished_on: envelope_end) }

      let!(:current_mentorship_period) do
        FactoryBot.create(
          :mentorship_period,
          mentee: ect_at_school_period,
          mentor: mentor_at_school_period_2,
          started_on: envelope_start,
          finished_on: envelope_end
        )
      end

      it "returns only eligible mentors" do
        expect(current_step.mentors_for_select.ids).to eq([mentor_at_school_period_1.id])
      end
    end
  end
end
