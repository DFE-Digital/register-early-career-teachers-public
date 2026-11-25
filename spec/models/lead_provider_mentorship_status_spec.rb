RSpec.describe LeadProviderMentorshipStatus do
  subject(:record) { FactoryBot.create(:lead_provider_mentorship_status) }

  it { is_expected.to validate_presence_of(:mentorship_period) }
  it { is_expected.to validate_presence_of(:lead_provider) }
  it { is_expected.to validate_presence_of(:status) }
  it { is_expected.to validate_presence_of(:reason) }
  it { is_expected.to validate_inclusion_of(:status).in_array(described_class.statuses.keys) }
  it { is_expected.to validate_inclusion_of(:reason).in_array(described_class.reasons.keys) }
  it { is_expected.to validate_uniqueness_of(:lead_provider_id).scoped_to(:mentorship_period_id) }

  describe "status assignment on creation" do
    subject { described_class.create!(mentorship_period:, lead_provider:) }

    let(:mentorship_period) { FactoryBot.create(:mentorship_period) }
    let(:lead_provider) { FactoryBot.create(:lead_provider) }

    it { is_expected.to have_attributes(status: "no-access-required", reason: "mentorship-expired") }
  end

  describe "#refresh!" do
    let(:mentee) { FactoryBot.create(:ect_at_school_period, :unfinished) }
    let(:mentor) { FactoryBot.create(:mentor_at_school_period, :unfinished, school: mentee.school) }
    let(:mentorship_period) { FactoryBot.create(:mentorship_period, :unfinished, mentee:, mentor:) }
    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:school_partnership) { FactoryBot.create(:school_partnership, :for_year, school: mentor.school, lead_provider:) }
    let!(:mentorship_status) { FactoryBot.create(:lead_provider_mentorship_status, mentorship_period:, lead_provider:, updated_at: 1.month.ago) }

    it "does not change updated_at when the status and reason are unchanged" do
      expect { mentorship_status.refresh! }.not_to(change { mentorship_status.reload.updated_at })
    end

    it "sets a status of no-access-required and reason of mentorship-expired when the mentorship period is finished" do
      mentorship_period.update!(finished_on: Date.current)

      expect { mentorship_status.refresh! }
        .to change { mentorship_status.reload.attributes.slice("status", "reason") }
        .from("status" => "access-and-support-only", "reason" => "no-known-training")
        .to("status" => "no-access-required", "reason" => "mentorship-expired")
    end

    it "sets a status of access-and-support-only and reason of completed-training when the mentor is ineligible for funding" do
      mentor.teacher.update!(
        mentor_became_ineligible_for_funding_on: Date.current,
        mentor_became_ineligible_for_funding_reason: "completed_declaration_received"
      )

      expect { mentorship_status.refresh! }
        .to change { mentorship_status.reload.attributes.slice("status", "reason") }
        .from("status" => "access-and-support-only", "reason" => "no-known-training")
        .to("status" => "access-and-support-only", "reason" => "completed-training")
    end

    it "sets a status of no-access-required and reason of ect-finished-training-with-provider when all of the ECT's training periods with the lead provider are finished" do
      # When the mentorship period is linked to the lead provider via the mentee training period we create here
      # it will be picked up by callbacks for refreshing the mentorship status automatically, so we need to override
      # the status and reason explicitly to get a different initial state for the test.
      FactoryBot.create(:training_period, :for_ect, ect_at_school_period: mentee, school_partnership:, finished_on: Date.yesterday)
      mentorship_status.update_columns(status: "access-and-support-only", reason: "no-known-training")

      expect { mentorship_status.refresh! }
        .to change { mentorship_status.reload.attributes.slice("status", "reason") }
        .from("status" => "access-and-support-only", "reason" => "no-known-training")
        .to("status" => "no-access-required", "reason" => "ect-finished-training-with-provider")
    end

    context "when the mentor has a training period with the lead provider" do
      it "sets a status of available-to-train and reason of available-to-train when the mentor has an unfinished training period" do
        FactoryBot.create(:training_period, :for_mentor, :unfinished, mentor_at_school_period: mentor, school_partnership:)

        expect { mentorship_status.refresh! }
          .to change { mentorship_status.reload.attributes.slice("status", "reason") }
          .from("status" => "access-and-support-only", "reason" => "no-known-training")
          .to("status" => "available-to-train", "reason" => "available-to-train")
      end

      it "sets a status of available-to-train and reason of available-to-train when the mentor has an training period that finishes in the future" do
        FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period: mentor, school_partnership:, finished_on: Date.tomorrow)

        expect { mentorship_status.refresh! }
          .to change { mentorship_status.reload.attributes.slice("status", "reason") }
          .from("status" => "access-and-support-only", "reason" => "no-known-training")
          .to("status" => "available-to-train", "reason" => "available-to-train")
      end
    end

    context "when the mentor only has a training period with a different lead provider" do
      let(:other_school_partnership) { FactoryBot.create(:school_partnership) }

      it "sets a status of available-to-train and reason of mentor-training-elsewhere when the mentor has an unfinished training period" do
        FactoryBot.create(:training_period, :for_mentor, :unfinished, mentor_at_school_period: mentor, school_partnership: other_school_partnership)

        expect { mentorship_status.refresh! }
          .to change { mentorship_status.reload.attributes.slice("status", "reason") }
          .from("status" => "access-and-support-only", "reason" => "no-known-training")
          .to("status" => "access-and-support-only", "reason" => "mentor-training-elsewhere")
      end

      it "sets a status of access-and-support-only and reason of mentor-training-elsewhere when the mentor has an training period that finishes in the future" do
        FactoryBot.create(:training_period, :for_mentor, mentor_at_school_period: mentor, school_partnership: other_school_partnership, finished_on: Date.tomorrow)

        expect { mentorship_status.refresh! }
          .to change { mentorship_status.reload.attributes.slice("status", "reason") }
          .from("status" => "access-and-support-only", "reason" => "no-known-training")
          .to("status" => "access-and-support-only", "reason" => "mentor-training-elsewhere")
      end
    end

    it "sets a status of access-and-support-only and reason of mentor-not-currently-training when the mentor only has past training periods" do
      FactoryBot.create(:training_period, :for_mentor, finished_on: 1.day.ago, mentor_at_school_period: mentor, school_partnership:)

      expect { mentorship_status.refresh! }
        .to change { mentorship_status.reload.attributes.slice("status", "reason") }
        .from("status" => "access-and-support-only", "reason" => "no-known-training")
        .to("status" => "access-and-support-only", "reason" => "mentor-not-currently-training")
    end
  end
end
