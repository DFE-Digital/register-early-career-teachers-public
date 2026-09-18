RSpec.describe CheckValidity do
  describe "#call" do
    it "raises an error on production" do
      allow(Rails.env).to receive(:production?).and_return(true)

      expect { described_class.new.call }.to raise_error(CheckValidity::ProductionGuardError, "Do not query live production data")
    end

    it "raises an error when no tables are specified" do
      expect { described_class.new.call(tables: []) }.to raise_error(ArgumentError, "No tables specified")
    end

    it "returns the number of invalid records" do
      expect(described_class.new.call(tables: %w[teachers])).to eq(0)
    end

    it "checks induction periods before teachers" do
      expect(described_class::TABLES).to eq(%w[induction_periods teachers])
    end

    describe "EAGER_LOAD" do
      it "has an entry for induction_periods preloading the teacher and their periods" do
        expect(described_class::EAGER_LOAD.fetch(:induction_periods)).to eq([{ teacher: :induction_periods }])
      end

      it "preloads nothing for tables without association-traversal validations" do
        expect(described_class::EAGER_LOAD.fetch(:teachers)).to eq([])
      end

      it "eager loads the declared associations on the scanned relation" do
        relation = double(ActiveRecord::Relation)
        allow(InductionPeriod).to receive(:includes).with({ teacher: :induction_periods }).and_return(relation)
        allow(relation).to receive(:find_in_batches).and_yield(InductionPeriod.none)

        described_class.new.call(tables: %w[induction_periods], batch_size: 10)

        expect(InductionPeriod).to have_received(:includes).with({ teacher: :induction_periods })
        expect(relation).to have_received(:find_in_batches)
      end
    end

    describe "when a table contains invalid records" do
      # Model invalid but peristable: anonymised_at set without a reason
      let!(:invalid_teacher) do
        teacher = FactoryBot.create(:teacher)
        teacher.update_columns(anonymised_at: Time.current)
        teacher
      end

      it "records the invalid record with its table, id and error messages" do
        expect(described_class.new.call(tables: %w[teachers])).to eq(1)

        invalid_record = InvalidRecord.find_by(table_name: "teachers", record_id: invalid_teacher.id)

        expect(invalid_record).to be_present
        expect(invalid_record.table_name).to eq("teachers")
        expect(invalid_record.record_id).to eq(invalid_teacher.id)
        expect(invalid_record.error_messages).to include("Anonymisation reason can't be blank")
      end

      it "does not record valid records" do
        valid_teacher = FactoryBot.create(:teacher)

        described_class.new.call(tables: %w[teachers])

        expect(InvalidRecord.where(table_name: "teachers", record_id: valid_teacher.id)).not_to exist
        expect(InvalidRecord.where(table_name: "teachers", record_id: invalid_teacher.id)).to exist
      end

      it "does not create duplicates when run more than once" do
        described_class.new.call(tables: %w[teachers])
        described_class.new.call(tables: %w[teachers])

        expect(InvalidRecord.where(table_name: "teachers", record_id: invalid_teacher.id).count).to eq(1)
      end

      it "updates the error messages on a subsequent run" do
        described_class.new.call(tables: %w[teachers])
        invalid_record = InvalidRecord.find_by(table_name: "teachers", record_id: invalid_teacher.id)

        expect(invalid_record.error_messages).to include("Anonymisation reason can't be blank")

        # Change the cause of invalidity so a re-run updates the same row
        invalid_teacher.update_columns(
          anonymised_at: nil,
          mentor_became_ineligible_for_funding_on: Time.current
        )

        described_class.new.call(tables: %w[teachers])
        invalid_record = InvalidRecord.find_by(table_name: "teachers", record_id: invalid_teacher.id)

        expect(invalid_record.error_messages).to include("reason why the mentor became ineligible for funding")

        expect(InvalidRecord.where(table_name: "teachers", record_id: invalid_teacher.id).count).to eq(1)
      end

      it "does not purge invalid records from other tables during a scan" do
        described_class.new.call(tables: %w[teachers])
        expect(InvalidRecord.where(table_name: "teachers", record_id: invalid_teacher.id)).to exist

        described_class.new.call(tables: %w[induction_periods])

        expect(InvalidRecord.where(table_name: "teachers", record_id: invalid_teacher.id)).to exist
      end

      it "removes records that have become valid on a subsequent run" do
        described_class.new.call(tables: %w[teachers])
        expect(InvalidRecord.where(table_name: "teachers", record_id: invalid_teacher.id)).to exist

        invalid_teacher.update_columns(anonymised_at: nil)
        described_class.new.call(tables: %w[teachers])

        expect(InvalidRecord.where(table_name: "teachers", record_id: invalid_teacher.id)).not_to exist
      end
    end

    it "creates no invalid records when all rows are valid" do
      FactoryBot.create(:teacher)

      expect { described_class.new.call(tables: %w[teachers]) }.not_to change(InvalidRecord, :count)
    end
  end
end
