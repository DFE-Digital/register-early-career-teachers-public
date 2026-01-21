RSpec.describe TeacherHistoryConverter::DateCorrector do
  subject(:date_corrector) do
    described_class.new(
      ect_induction_completion_date:,
      mentor_completion_date:
    )
  end

  let(:ect_induction_completion_date) { nil }
  let(:mentor_completion_date) { nil }

  describe "#corrected_start_date" do
    let(:induction_record) do
      FactoryBot.build(:ecf1_teacher_history_induction_record_row, start_date:, created_at:)
    end
    let(:start_date) { Date.new(2023, 9, 1) }
    let(:created_at) { Time.zone.local(2023, 9, 1, 12, 0, 0) }

    context "for the first induction record (sequence_number = 0)" do
      let(:sequence_number) { 0 }

      context "when start_date is the INDUCTION_RECORDS_ADDED_DATE (2022-02-09)" do
        let(:start_date) { Date.new(2022, 2, 9) }

        it "returns SERVICE_START_DATE (2021-09-01)" do
          expect(date_corrector.corrected_start_date(induction_record, sequence_number)).to eq(Date.new(2021, 9, 1))
        end
      end

      context "when start_date is earlier than created_at" do
        let(:start_date) { Date.new(2023, 9, 1) }
        let(:created_at) { Time.zone.local(2023, 9, 15, 12, 0, 0) }

        it "returns start_date" do
          expect(date_corrector.corrected_start_date(induction_record, sequence_number)).to eq(start_date)
        end
      end

      context "when created_at is earlier than start_date" do
        let(:start_date) { Date.new(2023, 9, 15) }
        let(:created_at) { Time.zone.local(2023, 9, 1, 12, 0, 0) }

        it "returns created_at as date" do
          expect(date_corrector.corrected_start_date(induction_record, sequence_number)).to eq(Date.new(2023, 9, 1))
        end
      end

      context "when calculated date would be before SERVICE_START_DATE (2021-09-01)" do
        let(:start_date) { Date.new(2021, 6, 1) }
        let(:created_at) { Time.zone.local(2021, 5, 15, 12, 0, 0) }

        it "returns SERVICE_START_DATE instead" do
          expect(date_corrector.corrected_start_date(induction_record, sequence_number)).to eq(Date.new(2021, 9, 1))
        end
      end
    end

    context "for subsequent induction records (sequence_number > 0)" do
      let(:sequence_number) { 1 }

      it "returns start_date regardless of created_at" do
        expect(date_corrector.corrected_start_date(induction_record, sequence_number)).to eq(start_date)
      end

      context "even when created_at is earlier" do
        let(:start_date) { Date.new(2023, 9, 15) }
        let(:created_at) { Time.zone.local(2023, 9, 1, 12, 0, 0) }

        it "still returns start_date" do
          expect(date_corrector.corrected_start_date(induction_record, sequence_number)).to eq(start_date)
        end
      end

      context "when start_date is before SERVICE_START_DATE (2021-09-01)" do
        let(:start_date) { Date.new(2021, 3, 15) }
        let(:created_at) { Time.zone.local(2021, 3, 10, 12, 0, 0) }

        it "returns SERVICE_START_DATE instead" do
          expect(date_corrector.corrected_start_date(induction_record, sequence_number)).to eq(Date.new(2021, 9, 1))
        end
      end
    end
  end

  describe "#corrected_end_date" do
    let(:induction_record) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date:,
        end_date:,
        created_at:,
        updated_at:,
        induction_status:,
        training_status:
      )
    end
    let(:start_date) { Date.new(2023, 9, 1) }
    let(:end_date) { Date.new(2024, 8, 31) }
    let(:created_at) { Time.zone.local(2023, 9, 1, 12, 0, 0) }
    let(:updated_at) { Time.zone.local(2024, 8, 31, 12, 0, 0) }
    let(:induction_status) { "active" }
    let(:training_status) { "active" }
    let(:induction_records) { [induction_record] }

    context "for ECTs" do
      let(:participant_type) { :ect }

      context "with more than 2 induction records and a completion date" do
        let(:ect_induction_completion_date) { Date.new(2024, 7, 15) }
        let(:induction_records) do
          [
            FactoryBot.build(:ecf1_teacher_history_induction_record_row, created_at: 1.day.ago),
            FactoryBot.build(:ecf1_teacher_history_induction_record_row, created_at: 2.days.ago),
            FactoryBot.build(:ecf1_teacher_history_induction_record_row, created_at: 3.days.ago)
          ]
        end

        context "for the last created induction record" do
          let(:induction_record) { induction_records.first } # most recent created_at

          it "returns the ECT induction completion date" do
            expect(date_corrector.corrected_end_date(induction_record, induction_records, participant_type:)).to eq(ect_induction_completion_date)
          end
        end

        context "for a non-last induction record" do
          let(:induction_record) { induction_records.last } # oldest created_at
          let(:end_date) { Date.new(2024, 8, 31) }

          before do
            induction_record.end_date = end_date
          end

          it "returns the minimum of end_date and completion date" do
            expect(date_corrector.corrected_end_date(induction_record, induction_records, participant_type:)).to eq(ect_induction_completion_date)
          end

          context "when end_date is earlier than completion date" do
            let(:end_date) { Date.new(2024, 6, 1) }

            before do
              induction_record.end_date = end_date
            end

            it "returns the end_date" do
              expect(date_corrector.corrected_end_date(induction_record, induction_records, participant_type:)).to eq(end_date)
            end
          end
        end
      end

      context "when last IR is leaving with flipped dates" do
        let(:induction_status) { "leaving" }
        let(:start_date) { Date.new(2024, 9, 1) }
        let(:end_date) { Date.new(2024, 1, 1) } # flipped: end before start

        it "returns updated_at as date" do
          expect(date_corrector.corrected_end_date(induction_record, induction_records, participant_type:)).to eq(updated_at.to_date)
        end
      end

      context "when there are exactly two IRs and last is completed" do
        let(:first_ir) do
          FactoryBot.build(
            :ecf1_teacher_history_induction_record_row,
            created_at: 2.days.ago,
            updated_at: Time.zone.local(2024, 6, 15, 12, 0, 0)
          )
        end
        let(:second_ir) do
          FactoryBot.build(
            :ecf1_teacher_history_induction_record_row,
            created_at: 1.day.ago,
            induction_status: "completed"
          )
        end
        let(:induction_records) { [first_ir, second_ir] }
        let(:induction_record) { first_ir }

        it "returns the first IR's updated_at as date" do
          expect(date_corrector.corrected_end_date(induction_record, induction_records, participant_type:)).to eq(Date.new(2024, 6, 15))
        end
      end

      context "in normal cases" do
        it "returns end_date" do
          expect(date_corrector.corrected_end_date(induction_record, induction_records, participant_type:)).to eq(end_date)
        end
      end

      context "when end_date is before SERVICE_START_DATE (prewash rule)" do
        context "for the first IR with a subsequent IR available" do
          let(:first_ir) do
            FactoryBot.build(
              :ecf1_teacher_history_induction_record_row,
              start_date: Date.new(2020, 9, 1),
              end_date: Date.new(2021, 3, 15), # invalid end_date
              created_at: Time.zone.local(2020, 9, 1, 12, 0, 0)
            )
          end
          let(:second_ir) do
            FactoryBot.build(
              :ecf1_teacher_history_induction_record_row,
              start_date: Date.new(2021, 9, 1),
              end_date: Date.new(2022, 8, 31),
              created_at: Time.zone.local(2021, 9, 1, 12, 0, 0)
            )
          end
          let(:induction_records) { [first_ir, second_ir] }
          let(:induction_record) { first_ir }

          it "uses the start_date of the next IR" do
            expect(date_corrector.corrected_end_date(induction_record, induction_records, participant_type:)).to eq(Date.new(2021, 9, 1))
          end
        end

        context "for a subsequent IR (not first)" do
          let(:first_ir) do
            FactoryBot.build(
              :ecf1_teacher_history_induction_record_row,
              start_date: Date.new(2020, 9, 1),
              end_date: Date.new(2020, 12, 31),
              created_at: Time.zone.local(2020, 9, 1, 12, 0, 0)
            )
          end
          let(:second_ir) do
            FactoryBot.build(
              :ecf1_teacher_history_induction_record_row,
              start_date: Date.new(2021, 1, 1),
              end_date: Date.new(2021, 3, 15), # invalid end_date
              created_at: Time.zone.local(2021, 6, 1, 12, 0, 0)
            )
          end
          let(:induction_records) { [first_ir, second_ir] }
          let(:induction_record) { second_ir }

          it "uses the created_at date of that IR" do
            expect(date_corrector.corrected_end_date(induction_record, induction_records, participant_type:)).to eq(Date.new(2021, 6, 1))
          end
        end

        context "for the first and only IR" do
          let(:induction_record) do
            FactoryBot.build(
              :ecf1_teacher_history_induction_record_row,
              start_date: Date.new(2020, 9, 1),
              end_date: Date.new(2021, 3, 15), # invalid end_date
              created_at: Time.zone.local(2020, 9, 1, 12, 0, 0)
            )
          end
          let(:induction_records) { [induction_record] }

          it "uses the created_at date since there is no next IR" do
            expect(date_corrector.corrected_end_date(induction_record, induction_records, participant_type:)).to eq(Date.new(2020, 9, 1))
          end
        end
      end
    end

    context "for mentors" do
      let(:participant_type) { :mentor }

      it "returns end_date in normal cases" do
        expect(date_corrector.corrected_end_date(induction_record, induction_records, participant_type:)).to eq(end_date)
      end
    end
  end

  describe "#corrected_training_period_end_date" do
    let(:induction_record) do
      FactoryBot.build(
        :ecf1_teacher_history_induction_record_row,
        start_date:,
        end_date:,
        created_at:,
        training_status:
      )
    end
    let(:start_date) { Date.new(2023, 9, 1) }
    let(:end_date) { Date.new(2024, 8, 31) }
    let(:created_at) { Time.zone.local(2023, 9, 1, 12, 0, 0) }
    let(:training_status) { "active" }
    let(:induction_records) { [induction_record] }

    context "with two IRs where only the last is deferred or withdrawn" do
      let(:first_ir) do
        FactoryBot.build(
          :ecf1_teacher_history_induction_record_row,
          created_at: 2.days.ago,
          end_date: Date.new(2024, 6, 30),
          training_status: "active"
        )
      end
      let(:second_ir) do
        FactoryBot.build(
          :ecf1_teacher_history_induction_record_row,
          created_at: 1.day.ago,
          end_date: Date.new(2024, 8, 31),
          training_status: "deferred"
        )
      end
      let(:induction_records) { [first_ir, second_ir] }
      let(:induction_record) { second_ir }

      it "returns the first IR's end_date" do
        expect(date_corrector.corrected_training_period_end_date(induction_record, induction_records, participant_type: :ect)).to eq(Date.new(2024, 6, 30))
      end
    end

    context "with more than one induction record" do
      let(:induction_records) do
        [
          FactoryBot.build(:ecf1_teacher_history_induction_record_row, created_at: 2.days.ago),
          FactoryBot.build(:ecf1_teacher_history_induction_record_row, created_at: 1.day.ago)
        ]
      end
      let(:induction_record) { induction_records.first }

      it "returns end_date" do
        expect(date_corrector.corrected_training_period_end_date(induction_record, induction_records, participant_type: :ect)).to eq(induction_record.end_date)
      end
    end

    context "for ECTs" do
      let(:participant_type) { :ect }

      it "returns end_date" do
        expect(date_corrector.corrected_training_period_end_date(induction_record, induction_records, participant_type:)).to eq(end_date)
      end
    end

    context "for mentors with a single IR" do
      let(:participant_type) { :mentor }

      context "when there is an end_date" do
        it "returns end_date" do
          expect(date_corrector.corrected_training_period_end_date(induction_record, induction_records, participant_type:)).to eq(end_date)
        end
      end

      context "when there is no end_date" do
        let(:end_date) { nil }

        context "and mentor has no completion date" do
          let(:mentor_completion_date) { nil }

          it "returns nil" do
            expect(date_corrector.corrected_training_period_end_date(induction_record, induction_records, participant_type:)).to be_nil
          end
        end

        context "and mentor has completion_date before SERVICE_START_DATE (2021-09-01)" do
          let(:mentor_completion_date) { Date.new(2021, 3, 15) }

          it "returns 31 August following the start_date" do
            expect(date_corrector.corrected_training_period_end_date(induction_record, induction_records, participant_type:)).to eq(Date.new(2024, 8, 31))
          end
        end

        context "and mentor has completion_date on or after SERVICE_START_DATE" do
          let(:mentor_completion_date) { Date.new(2023, 11, 15) }

          it "returns 31 August following the completion_date" do
            expect(date_corrector.corrected_training_period_end_date(induction_record, induction_records, participant_type:)).to eq(Date.new(2024, 8, 31))
          end

          context "when completion_date is after August" do
            let(:mentor_completion_date) { Date.new(2023, 10, 15) }

            it "returns 31 August of the following year" do
              expect(date_corrector.corrected_training_period_end_date(induction_record, induction_records, participant_type:)).to eq(Date.new(2024, 8, 31))
            end
          end

          context "when completion_date is before September" do
            let(:mentor_completion_date) { Date.new(2024, 3, 15) }

            it "returns 31 August of the same year" do
              expect(date_corrector.corrected_training_period_end_date(induction_record, induction_records, participant_type:)).to eq(Date.new(2024, 8, 31))
            end
          end
        end
      end
    end
  end
end
