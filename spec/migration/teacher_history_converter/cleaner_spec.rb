RSpec.describe TeacherHistoryConverter::Cleaner do
  subject(:cleaner) { described_class.new(raw_induction_records) }

  describe "#induction_records" do
    context "when end_date is before SERVICE_START_DATE (2021-09-01)" do
      context "for the first IR with a subsequent IR available" do
        let(:first_induction_record) do
          FactoryBot.build(
            :ecf1_teacher_history_induction_record_row,
            start_date: Date.new(2020, 9, 1),
            end_date: Date.new(2021, 3, 15),
            created_at: Time.zone.local(2020, 9, 1, 12, 0, 0)
          )
        end
        let(:second_induction_record) do
          FactoryBot.build(
            :ecf1_teacher_history_induction_record_row,
            start_date: Date.new(2021, 9, 1),
            end_date: Date.new(2022, 8, 31),
            created_at: Time.zone.local(2021, 9, 1, 12, 0, 0)
          )
        end
        let(:raw_induction_records) { [first_induction_record, second_induction_record] }

        it "corrects the first IR's end_date to the second IR's start_date" do
          result = cleaner.induction_records
          expect(result.first.end_date).to eq(Date.new(2021, 9, 1))
        end

        it "preserves other attributes of the first IR" do
          result = cleaner.induction_records
          expect(result.first.start_date).to eq(first_induction_record.start_date)
          expect(result.first.induction_record_id).to eq(first_induction_record.induction_record_id)
        end

        it "does not modify the second IR" do
          result = cleaner.induction_records
          expect(result.last).to eq(second_induction_record)
        end
      end

      context "for a subsequent IR (not first)" do
        let(:first_induction_record) do
          FactoryBot.build(
            :ecf1_teacher_history_induction_record_row,
            start_date: Date.new(2020, 9, 1),
            end_date: Date.new(2020, 12, 31),
            created_at: Time.zone.local(2020, 9, 1, 12, 0, 0)
          )
        end
        let(:second_induction_record) do
          FactoryBot.build(
            :ecf1_teacher_history_induction_record_row,
            start_date: Date.new(2021, 1, 1),
            end_date: Date.new(2021, 3, 15),
            created_at: Time.zone.local(2021, 6, 1, 12, 0, 0)
          )
        end
        let(:raw_induction_records) { [first_induction_record, second_induction_record] }

        it "corrects the second IR's end_date to its created_at date" do
          result = cleaner.induction_records
          expect(result.last.end_date).to eq(Date.new(2021, 6, 1))
        end
      end

      context "for the first and only IR" do
        let(:only_induction_record) do
          FactoryBot.build(
            :ecf1_teacher_history_induction_record_row,
            start_date: Date.new(2020, 9, 1),
            end_date: Date.new(2021, 3, 15),
            created_at: Time.zone.local(2020, 9, 1, 12, 0, 0)
          )
        end
        let(:raw_induction_records) { [only_induction_record] }

        it "corrects the end_date to its created_at date" do
          result = cleaner.induction_records
          expect(result.first.end_date).to eq(Date.new(2020, 9, 1))
        end
      end
    end

    context "when end_date is on or after SERVICE_START_DATE" do
      let(:induction_record) do
        FactoryBot.build(
          :ecf1_teacher_history_induction_record_row,
          start_date: Date.new(2021, 9, 1),
          end_date: Date.new(2022, 8, 31),
          created_at: Time.zone.local(2021, 9, 1, 12, 0, 0)
        )
      end
      let(:raw_induction_records) { [induction_record] }

      it "does not modify the end_date" do
        result = cleaner.induction_records
        expect(result.first).to eq(induction_record)
      end
    end

    context "when end_date is nil" do
      let(:induction_record) do
        FactoryBot.build(
          :ecf1_teacher_history_induction_record_row,
          start_date: Date.new(2021, 9, 1),
          end_date: nil,
          created_at: Time.zone.local(2021, 9, 1, 12, 0, 0)
        )
      end
      let(:raw_induction_records) { [induction_record] }

      it "does not modify the record" do
        result = cleaner.induction_records
        expect(result.first).to eq(induction_record)
      end
    end

    context "with empty induction records" do
      let(:raw_induction_records) { [] }

      it "returns an empty array" do
        expect(cleaner.induction_records).to eq([])
      end
    end

    context "with multiple consecutive invalid end_dates" do
      let(:first_induction_record) do
        FactoryBot.build(
          :ecf1_teacher_history_induction_record_row,
          start_date: Date.new(2020, 9, 1),
          end_date: Date.new(2020, 12, 31),
          created_at: Time.zone.local(2020, 9, 1, 12, 0, 0)
        )
      end
      let(:second_induction_record) do
        FactoryBot.build(
          :ecf1_teacher_history_induction_record_row,
          start_date: Date.new(2021, 1, 1),
          end_date: Date.new(2021, 3, 15),
          created_at: Time.zone.local(2021, 1, 1, 12, 0, 0)
        )
      end
      let(:third_induction_record) do
        FactoryBot.build(
          :ecf1_teacher_history_induction_record_row,
          start_date: Date.new(2021, 9, 1),
          end_date: Date.new(2022, 8, 31),
          created_at: Time.zone.local(2021, 9, 1, 12, 0, 0)
        )
      end
      let(:raw_induction_records) { [first_induction_record, second_induction_record, third_induction_record] }

      it "corrects the first IR's end_date to the second IR's start_date" do
        result = cleaner.induction_records
        expect(result[0].end_date).to eq(Date.new(2021, 1, 1))
      end

      it "corrects the second IR's end_date to the third IR's start_date" do
        result = cleaner.induction_records
        expect(result[1].end_date).to eq(Date.new(2021, 9, 1))
      end

      it "does not modify the third IR" do
        result = cleaner.induction_records
        expect(result[2].end_date).to eq(Date.new(2022, 8, 31))
      end
    end

    context "with all IRs having invalid end_dates and no valid successor" do
      let(:first_induction_record) do
        FactoryBot.build(
          :ecf1_teacher_history_induction_record_row,
          start_date: Date.new(2020, 9, 1),
          end_date: Date.new(2020, 12, 31),
          created_at: Time.zone.local(2020, 9, 1, 12, 0, 0)
        )
      end
      let(:second_induction_record) do
        FactoryBot.build(
          :ecf1_teacher_history_induction_record_row,
          start_date: Date.new(2021, 1, 1),
          end_date: Date.new(2021, 3, 15),
          created_at: Time.zone.local(2021, 1, 1, 12, 0, 0)
        )
      end
      let(:third_induction_record) do
        FactoryBot.build(
          :ecf1_teacher_history_induction_record_row,
          start_date: Date.new(2021, 4, 1),
          end_date: Date.new(2021, 6, 30),
          created_at: Time.zone.local(2021, 4, 1, 12, 0, 0)
        )
      end
      let(:raw_induction_records) { [first_induction_record, second_induction_record, third_induction_record] }

      it "corrects the first IR's end_date to the second IR's start_date" do
        result = cleaner.induction_records
        expect(result[0].end_date).to eq(Date.new(2021, 1, 1))
      end

      it "corrects the second IR's end_date to the third IR's start_date" do
        result = cleaner.induction_records
        expect(result[1].end_date).to eq(Date.new(2021, 4, 1))
      end

      it "corrects the third IR's end_date to its created_at (no successor)" do
        result = cleaner.induction_records
        expect(result[2].end_date).to eq(Date.new(2021, 4, 1))
      end
    end

    context "with mixed valid and invalid end_dates" do
      let(:first_induction_record) do
        FactoryBot.build(
          :ecf1_teacher_history_induction_record_row,
          start_date: Date.new(2020, 9, 1),
          end_date: Date.new(2020, 12, 31),
          created_at: Time.zone.local(2020, 9, 1, 12, 0, 0)
        )
      end
      let(:second_induction_record) do
        FactoryBot.build(
          :ecf1_teacher_history_induction_record_row,
          start_date: Date.new(2021, 9, 1),
          end_date: Date.new(2022, 8, 31),
          created_at: Time.zone.local(2021, 9, 1, 12, 0, 0)
        )
      end
      let(:third_induction_record) do
        FactoryBot.build(
          :ecf1_teacher_history_induction_record_row,
          start_date: Date.new(2020, 1, 1),
          end_date: Date.new(2020, 6, 30),
          created_at: Time.zone.local(2022, 9, 1, 12, 0, 0)
        )
      end
      let(:raw_induction_records) { [first_induction_record, second_induction_record, third_induction_record] }

      it "corrects the first IR's end_date to the second IR's start_date" do
        result = cleaner.induction_records
        expect(result[0].end_date).to eq(Date.new(2021, 9, 1))
      end

      it "does not modify the second IR (valid end_date)" do
        result = cleaner.induction_records
        expect(result[1].end_date).to eq(Date.new(2022, 8, 31))
      end

      it "corrects the third IR's end_date to its created_at (no successor)" do
        result = cleaner.induction_records
        expect(result[2].end_date).to eq(Date.new(2022, 9, 1))
      end
    end

    context "when first IR is valid but second is invalid" do
      let(:first_induction_record) do
        FactoryBot.build(
          :ecf1_teacher_history_induction_record_row,
          start_date: Date.new(2021, 9, 1),
          end_date: Date.new(2022, 8, 31),
          created_at: Time.zone.local(2021, 9, 1, 12, 0, 0)
        )
      end
      let(:second_induction_record) do
        FactoryBot.build(
          :ecf1_teacher_history_induction_record_row,
          start_date: Date.new(2020, 9, 1),
          end_date: Date.new(2021, 3, 15),
          created_at: Time.zone.local(2022, 9, 1, 12, 0, 0)
        )
      end
      let(:raw_induction_records) { [first_induction_record, second_induction_record] }

      it "does not modify the first IR" do
        result = cleaner.induction_records
        expect(result[0].end_date).to eq(Date.new(2022, 8, 31))
      end

      it "corrects the second IR's end_date to its created_at" do
        result = cleaner.induction_records
        expect(result[1].end_date).to eq(Date.new(2022, 9, 1))
      end
    end
  end
end
