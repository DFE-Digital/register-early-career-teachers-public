describe TeacherHistoryConverter::Cleaner::CloseOngoingRecordsAfterInductionCompletion do
  subject(:result) { described_class.new(raw_induction_records, induction_completion_date:).induction_records }

  describe "#induction_records" do
    let(:induction_completion_date) { nil }
    let(:final_end_date) { nil }

    let(:induction_record_1) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: Date.new(2021, 9, 1),
        end_date: Date.new(2022, 3, 15),
        created_at: Time.zone.local(2020, 9, 1, 12, 0, 0)
      )
    end
    let(:induction_record_2) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: Date.new(2022, 3, 15),
        end_date: Date.new(2022, 5, 1),
        created_at: Time.zone.local(2023, 3, 15, 14, 0, 0)
      )
    end
    let(:induction_record_3) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date: Date.new(2022, 5, 1),
        end_date: final_end_date,
        created_at: Time.zone.local(2022, 5, 1, 12, 0, 0)
      )
    end
    let(:raw_induction_records) { [induction_record_1, induction_record_2, induction_record_3] }

    context "when the induction_completion_date is blank" do
      it "returns all the induction records" do
        expect(result).to match raw_induction_records
      end
    end

    context "when the induction_completion_date is set" do
      let(:induction_completion_date) { induction_record_1.end_date }

      context "when the induction_record has no end_date and the start_date is later than the completion date" do
        it "sets the end_date to the start_date + 1.day" do
          expect(result.last.end_date).to eq induction_record_3.start_date + 1.day
        end
      end

      context "when the induction_record has no end_date and the start_date is before the the completion date" do
        let(:induction_completion_date) { induction_record_3.start_date + 1.month }

        it "sets the end_date to the induction_completion_date" do
          expect(result.last.end_date).to eq induction_completion_date
        end
      end

      context "when the induction_record has an end_date" do
        let(:final_end_date) { 1.week.ago }

        it "does not change the end_date" do
          aggregate_failures do
            expect(result[0].end_date).to eq induction_record_1.end_date
            expect(result[1].end_date).to eq induction_record_2.end_date
            expect(result[2].end_date).to eq final_end_date
          end
        end
      end
    end
  end
end
