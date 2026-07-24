RSpec.describe Schools::MentorAssignment::MentorshipPeriods::DatesResolver do
  subject(:service) do
    described_class.new(
      ect_at_school_period:,
      mentor_at_school_period:,
      mentor_is_transferring_schools:
    )
  end

  let(:ect_at_school_period) do
    FactoryBot.create(
      :ect_at_school_period,
      started_on: ect_started_on,
      finished_on: ect_finished_on
    )
  end
  let(:mentor_at_school_period) do
    FactoryBot.create(
      :mentor_at_school_period,
      started_on: mentor_started_on,
      finished_on: mentor_finished_on
    )
  end

  let(:ect_started_on) { 2.years.ago }
  let(:mentor_started_on) { 2.years.ago }
  let(:ect_finished_on) { nil }
  let(:mentor_finished_on) { nil }
  let(:mentor_is_transferring_schools) { false }

  describe "#earliest_possible_start" do
    subject(:earliest_possible_start) { service.earliest_possible_start }

    context "when the mentor is not transferring schools" do
      let(:mentor_is_transferring_schools) { false }

      context "and both the ECT and the mentor started at the school " \
              "in the past" do
        let(:ect_started_on) { 2.years.ago }
        let(:mentor_started_on) { 1.year.ago }

        it { is_expected.to eq(Date.current) }
      end

      context "and both the ECT and the mentor are due to start at the " \
              "school in the future, and the mentee starts later" do
        let(:ect_started_on) { 3.months.from_now }
        let(:mentor_started_on) { 1.month.from_now }

        it { is_expected.to eq(ect_at_school_period.started_on) }
      end

      context "and both the ECT and the mentor are due to start at the " \
              "school in the future, and the mentor starts later" do
        let(:ect_started_on) { 1.month.from_now }
        let(:mentor_started_on) { 3.months.from_now }

        it { is_expected.to eq(mentor_at_school_period.started_on) }
      end

      context "and the ECT started at the school in the past, but the mentor " \
              "is due to start at the school in the future" do
        let(:ect_started_on) { 6.months.ago }
        let(:mentor_started_on) { 1.month.from_now }

        it { is_expected.to eq(mentor_at_school_period.started_on) }
      end

      context "and the mentor started at the school in the past, but the ECT " \
              "is due to start at the school in the future" do
        let(:ect_started_on) { 1.month.from_now }
        let(:mentor_started_on) { 6.months.ago }

        it { is_expected.to eq(ect_at_school_period.started_on) }
      end
    end

    context "when the mentor is transferring schools" do
      let(:mentor_is_transferring_schools) { true }

      context "and the ECT has no previous mentorships" do
        context "and the ECT started at the school after the mentor" do
          let(:ect_started_on) { 1.year.ago }
          let(:mentor_started_on) { 2.years.ago }

          it { is_expected.to eq(ect_at_school_period.started_on) }
        end

        context "and the mentor started at the school after the ECT" do
          let(:ect_started_on) { 2.years.ago }
          let(:mentor_started_on) { 1.year.ago }

          it { is_expected.to eq(mentor_at_school_period.started_on) }
        end
      end

      context "and the ECT has a previous mentorship" do
        let(:previous_mentorship_started_on) { 1.year.ago.to_date }

        let(:previous_mentor_at_school_period) do
          FactoryBot.create(
            :mentor_at_school_period,
            :ongoing,
            started_on: previous_mentorship_started_on,
            school: ect_at_school_period.school
          )
        end

        let!(:previous_mentorship_period) do
          FactoryBot.create(
            :mentorship_period,
            mentee: ect_at_school_period,
            mentor: previous_mentor_at_school_period,
            started_on: previous_mentorship_started_on,
            finished_on: 2.weeks.ago.to_date
          )
        end

        context "and both the ECT and the new mentor started at the school " \
                "in the past" do
          let(:ect_started_on) { 2.years.ago }
          let(:mentor_started_on) { 1.month.ago }

          it { is_expected.to eq(Date.current) }
        end

        context "and the new mentor starts at the school in the future" do
          let(:ect_started_on) { 2.years.ago }
          let(:mentor_started_on) { 1.month.from_now }

          it { is_expected.to eq(mentor_at_school_period.started_on) }
        end
      end
    end
  end

  describe "#latest_possible_finish" do
    subject(:latest_possible_finish) { service.latest_possible_finish }

    context "when neither the ECT nor the mentor are due to leave the school" do
      let(:ect_finished_on) { nil }
      let(:mentor_finished_on) { nil }

      it { is_expected.to be_nil }
    end

    context "when only the ECT is due to leave the school" do
      let(:ect_finished_on) { 2.years.from_now }
      let(:mentor_finished_on) { nil }

      it { is_expected.to eq(ect_at_school_period.finished_on) }
    end

    context "when only the mentor is due to leave the school" do
      let(:ect_finished_on) { nil }
      let(:mentor_finished_on) { 2.years.from_now }

      it { is_expected.to eq(mentor_at_school_period.finished_on) }
    end

    context "when the ECT is due to leave the school before the mentor" do
      let(:ect_finished_on) { 3.months.from_now }
      let(:mentor_finished_on) { 6.months.from_now }

      it { is_expected.to eq(ect_at_school_period.finished_on) }
    end

    context "when the mentor is due to leave the school before the ECT" do
      let(:ect_finished_on) { 6.months.from_now }
      let(:mentor_finished_on) { 3.months.from_now }

      it { is_expected.to eq(mentor_at_school_period.finished_on) }
    end
  end
end
