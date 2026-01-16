class TeacherHistoryConverter::ECT::AllInductionRecords
  def initialize(ecf1_teacher_history:, ecf2_teacher_history:)
    @ecf1_teacher_history = ecf1_teacher_history
    @ecf2_teacher_history = ecf2_teacher_history
  end

  def convert
    ecf1_teacher_history.induction_records(migration_mode: :latest_induction_records).each_with_index do |induction_record, _i|
      add_induction_record_to_ecf2_teacher_history(induction_record)
    end
  end

private

  def add_induction_record_to_ecf2_teacher_history(induction_record)
    # Step 1
    #
    # ECT at school period - do we:
    # - extend an existing ECT at school period?
    # - create a new ECT at school period?
    # - do nothing
    #
    # Step 2:
    #
    # Training period - do we:
    # - extend an existing training period?
    # - create a new training period
    # - do nothing
  end
end
