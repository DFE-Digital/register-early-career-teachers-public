RSpec.describe API::Teachers::ResumeUnknownMentor, type: :model do
  subject(:instance) do
    described_class.new(
      lead_provider_id:,
      teacher_api_id:
    )
  end

  let(:school) { FactoryBot.create(:school) }
  let(:previous_lead_provider) { FactoryBot.create(:lead_provider) }
  let(:previous_school_partnership) { FactoryBot.create(:school_partnership, :for_year, school:, lead_provider: previous_lead_provider) }
  let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :unfinished, school:) }
  let!(:previous_training_period) { FactoryBot.create(:training_period, :for_mentor, :withdrawn, school_partnership: previous_school_partnership, mentor_at_school_period:) }

  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:lead_provider_id) { lead_provider.id }
  let(:teacher_api_id) { mentor_at_school_period.teacher.api_id }

  let!(:ect_at_school_period) do
    FactoryBot.create(:ect_at_school_period, school:, started_on: 1.month.ago, finished_on: nil).tap do |esp|
      FactoryBot.create(:training_period, :unfinished, :with_school_partnership, ect_at_school_period: esp, lead_provider:)
    end
  end

  let(:school_partnership) { ect_at_school_period.training_periods.first.school_partnership }
  let!(:mentorship_period) { FactoryBot.create(:mentorship_period, mentor: mentor_at_school_period, mentee: ect_at_school_period) }

  describe "validations" do
    it { is_expected.to be_valid }

    it { is_expected.to validate_presence_of(:lead_provider_id).with_message("Enter a '#/lead_provider_id'.") }
    it { is_expected.to validate_presence_of(:teacher_api_id).with_message("Enter a '#/teacher_api_id'.") }

    context "when the `lead_provider` does not exist" do
      let(:lead_provider_id) { 9999 }

      it { is_expected.to have_one_error_only }
      it { is_expected.to have_api_error(:lead_provider_id, "The '#/lead_provider_id' you have entered is invalid.") }
    end

    context "when the teacher does not exist" do
      let(:teacher_api_id) { "non-existent-participant-id" }

      it { is_expected.to have_one_error_only }
      it { is_expected.to have_api_error(:teacher_api_id, "Your update cannot be made as the '#/teacher_api_id' is not recognised. Check teacher details and try again.") }
    end

    context "when training period has finished today" do
      let!(:previous_training_period) { FactoryBot.create(:training_period, :for_mentor, :withdrawn, school_partnership: previous_school_partnership, mentor_at_school_period:, finished_on: Date.current, withdrawn_at: Date.current) }

      it { is_expected.to have_one_error_per_attribute }
      it { is_expected.to have_api_error(:teacher_api_id, "You cannot resume a teacher on the same day they were withdrawn or deferred. Resume them tomorrow or later.") }
    end

    context "when teacher training period is active/ongoing" do
      let!(:previous_training_period) { FactoryBot.create(:training_period, :for_mentor, :unfinished, school_partnership: previous_school_partnership, mentor_at_school_period:) }

      it { is_expected.to have_one_error_per_attribute }
      it { is_expected.to have_api_error(:teacher_api_id, "The '#/teacher_api_id' is already active.") }
    end

    context "when teacher has already trained with the lead provider" do
      let!(:previous_training_period) { FactoryBot.create(:training_period, :for_mentor, :withdrawn, school_partnership:, mentor_at_school_period:) }

      it { is_expected.to have_one_error_per_attribute }
      it { is_expected.to have_api_error(:teacher_api_id, "The '#/teacher_api_id' has already trained with the lead provider") }
    end

    context "when teacher has not been selected for a mentorship with an ECT training with the lead provider" do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :with_training_period, school:, started_on: 1.month.ago, finished_on: nil) }

      it { is_expected.to have_one_error_per_attribute }
      it { is_expected.to have_api_error(:teacher_api_id, "The '#/teacher_api_id' has not been selected as a mentor for a teacher you are training") }
    end

    context "when at school period is finished" do
      # this will finish the mentorship period
      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, school:, finished_on: 1.day.ago) }

      it { is_expected.to have_one_error_per_attribute }
      it { is_expected.to have_api_error(:teacher_api_id, "The '#/teacher_api_id' has not been selected as a mentor for a teacher you are training") }
    end
  end
end
