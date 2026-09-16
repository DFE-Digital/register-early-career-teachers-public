RSpec.describe DataCorrections::BackfillMentorFundingEligibility do
  subject(:correction) do
    described_class.new(
      expected_count:,
      author:
    )
  end

  let(:expected_count) { 1 }
  let(:author) { Events::SystemAuthor.new }
  let(:teacher) { FactoryBot.create(:teacher) }
  let(:school) { FactoryBot.create(:school) }

  let!(:mentor_at_school_period) do
    FactoryBot.create(
      :mentor_at_school_period,
      :unfinished,
      teacher:,
      school:,
      started_on: 2.years.ago
    )
  end

  let!(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      teacher: FactoryBot.create(:teacher),
      school:,
      started_on: 2.years.ago,
      finished_on: 6.months.ago
    )
  end

  let!(:mentorship_period) do
    FactoryBot.create(
      :mentorship_period,
      mentor: mentor_at_school_period,
      mentee: ect_at_school_period,
      started_on: 1.year.ago,
      finished_on: 6.months.ago
    )
  end

  let!(:training_period) do
    FactoryBot.create(
      :training_period,
      :for_mentor,
      :provider_led,
      :unfinished,
      mentor_at_school_period:,
      started_on: 5.months.ago
    )
  end

  describe "#preview" do
    it "includes eligible mentors without requiring their periods to overlap" do
      expect(mentorship_period.finished_on).to be < training_period.started_on
      expect(correction.preview).to contain_exactly(teacher.id)
    end

    context "when the mentor is already eligible" do
      before do
        teacher.update!(
          mentor_first_became_eligible_for_training_at: 1.day.ago
        )
      end

      it "excludes the mentor" do
        expect(correction.preview).to be_empty
      end
    end

    context "when the mentor is ineligible" do
      before do
        teacher.update!(
          mentor_became_ineligible_for_funding_on: 1.day.ago,
          mentor_became_ineligible_for_funding_reason:
            "completed_during_early_roll_out"
        )
      end

      it "excludes the mentor" do
        expect(correction.preview).to be_empty
      end
    end

    context "when the mentor has not been assigned to an ECT" do
      before do
        mentorship_period.destroy!
      end

      it "excludes the mentor" do
        expect(correction.preview).to be_empty
      end
    end

    context "when the mentor has no mentor training period" do
      before do
        training_period.destroy!
      end

      it "excludes the mentor" do
        expect(correction.preview).to be_empty
      end
    end

    context "when the mentor has been anonymised" do
      before do
        teacher.update_column(:anonymised_at, Time.zone.now)
      end

      it "excludes the mentor" do
        expect(correction.preview).to be_empty
      end
    end
  end

  describe "#call" do
    it "sets mentor funding eligibility at the time of the correction" do
      freeze_time do
        expect { correction.call }
          .to change {
            teacher.reload
              .mentor_first_became_eligible_for_training_at
          }
          .from(nil).to(Time.zone.now)
      end
    end

    it "returns the corrected teacher IDs" do
      expect(correction.call).to contain_exactly(teacher.id)
    end

    context "when the candidate count differs from the expected count" do
      let(:expected_count) { 2 }

      it "raises an error without changing the teacher" do
        expect { correction.call }
          .to raise_error(
            described_class::UnexpectedCandidateCount,
            "Expected 2 candidates, found 1"
          )

        expect(
          teacher.reload
            .mentor_first_became_eligible_for_training_at
        ).to be_nil
      end
    end
  end
end
