describe ECF2TeacherHistory do
  subject { ECF2TeacherHistory.new(trn:, trs_first_name:, trs_last_name:, corrected_name:, **other_arguments) }

  let(:trn) { "2345678" }
  let(:trs_first_name) { "Colin" }
  let(:trs_last_name) { "Jeavons" }
  let(:corrected_name) { "Tim Stamper" }

  let(:mentorship_period_rows) do
    [ECF2TeacherHistory::MentorshipPeriodRow.new(started_on: 1.month.ago.to_date, finished_on: 1.week.ago.to_date)]
  end

  let(:training_period_rows) do
    [ECF2TeacherHistory::TrainingPeriodRow.new(started_on: 1.month.ago.to_date, finished_on: 1.week.ago.to_date)]
  end

  let(:ect_at_school_period_rows) do
    [
      ECF2TeacherHistory::ECTAtSchoolPeriodRow.new(
        started_on: 1.month.ago.to_date,
        finished_on: 1.week.ago.to_date,
        mentorship_period_rows:,
        training_period_rows:
      )
    ]
  end

  let(:mentor_at_school_period_rows) do
    [
      ECF2TeacherHistory::MentorAtSchoolPeriodRow.new(
        started_on: 1.month.ago.to_date,
        finished_on: 1.week.ago.to_date,
        mentorship_period_rows:
      )
    ]
  end

  let(:other_arguments) { {} }

  describe "#initialize" do
    it "can be initialized with trn and name fields" do
      expect(subject.trn).to eql(trn)
      expect(subject.trs_first_name).to eql(trs_first_name)
      expect(subject.trs_last_name).to eql(trs_last_name)
      expect(subject.corrected_name).to eql(corrected_name)
    end

    context "when ect_at_school_period_rows are present" do
      let(:other_arguments) { { ect_at_school_period_rows: } }

      it "can be initialized with ect_at_school_period_rows" do
        expect(subject.ect_at_school_period_rows).to eql(ect_at_school_period_rows)
      end
    end

    context "when mentor_at_school_period_rows are present" do
      let(:other_arguments) { { mentor_at_school_period_rows: } }

      it "can be initialized with mentor_at_school_period_rows" do
        expect(subject.mentor_at_school_period_rows).to eql(mentor_at_school_period_rows)
      end
    end
  end
end
