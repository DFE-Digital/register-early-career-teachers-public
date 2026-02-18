class TeacherHistoryConverter::Cleaner::AdjustInitialInductionRecordStartDates
  INDUCTION_RECORD_INTRODUCTION_DATE = Date.new(2022, 2, 9).freeze
  REPLACEMENT_START_DATE = Date.new(2021, 9, 1).freeze

  def initialize(raw_induction_records)
    @raw_induction_records = raw_induction_records
  end

  def induction_records
    @raw_induction_records.dup.tap do |fixed_induction_records|
      if (first_ir = fixed_induction_records[0]) && (first_ir.start_date == INDUCTION_RECORD_INTRODUCTION_DATE)
        first_ir.start_date = REPLACEMENT_START_DATE
      end
    end
  end
end
