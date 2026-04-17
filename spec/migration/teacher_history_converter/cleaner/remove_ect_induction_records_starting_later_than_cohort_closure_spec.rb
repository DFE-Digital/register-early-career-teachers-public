describe TeacherHistoryConverter::Cleaner::RemoveECTInductionRecordsStartingLaterThanCohortClosure do
  subject(:cleaner) { described_class.new(raw_induction_records, participant_type) }

  let(:cohort_2021_cut_off) { TeacherHistoryConverter::Cleaner::CohortCutOffDates::COHORT_2021_CUTOFF_DATE }
  let(:cohort_2022_cut_off) { TeacherHistoryConverter::Cleaner::CohortCutOffDates::COHORT_2022_CUTOFF_DATE }

  describe "#induction_records" do
    let(:start_date) { cohort_2021_cut_off + 1.week }
    let(:cohort_year) { 2021 }

    let(:participant_type) { :ect }

    let(:induction_record_1) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: Date.new(2021, 9, 1),
        end_date: Date.new(2022, 3, 15),
        cohort_year:
      )
    end
    let(:induction_record_2) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: Date.new(2022, 6, 1),
        end_date: start_date,
        cohort_year:
      )
    end
    let(:induction_record_3) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date:,
        end_date: start_date + 1.year,
        cohort_year:
      )
    end
    let(:raw_induction_records) { [induction_record_1, induction_record_2, induction_record_3] }

    it "removes induction records that start after the cut off date" do
      expect(cleaner.induction_records).to contain_exactly(induction_record_1, induction_record_2)
    end

    context "when the cohort is 2022" do
      let(:start_date) { cohort_2022_cut_off + 1.week }
      let(:cohort_year) { 2022 }

      it "removes induction records that start after the cut off date" do
        expect(cleaner.induction_records).to contain_exactly(induction_record_1, induction_record_2)
      end
    end

    context "when the participant_type is a Mentor" do
      let(:participant_type) { :mentor }

      it "does not remove any records" do
        expect(cleaner.induction_records).to match_array raw_induction_records
      end
    end
  end
end
