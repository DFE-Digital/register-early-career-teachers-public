class TeacherHistoryConverter::MigrationStrategy
  attr_accessor :ecf1_teacher_history

  def initialize(ecf1_teacher_history)
    @ecf1_teacher_history = ecf1_teacher_history
  end

  def strategy
    if teacher_history_meets_premium_criteria?
      :all_induction_records
    else
      :latest_induction_records
    end
  end

private

  def teacher_history_meets_premium_criteria?
    below_threshold_for_induction_records &&
      has_not_been_withdrawn_or_deferred? &&
      is_not_induction_completed? &&
      dates_are_in_the_right_order_for?(ecf1_teacher_history.ect&.induction_records) &&
      dates_are_in_the_right_order_for?(ecf1_teacher_history.mentor&.induction_records)
  end

  def dates_are_in_the_right_order_for?(induction_records)
    return true if induction_records.blank?

    previous_induction_record = nil
    induction_records.sort_by(&:created_at).all? do |induction_record|
      result = if induction_record.dates_in_order?
                 if previous_induction_record.present?
                   previous_induction_record.end_date.present? && previous_induction_record.end_date < induction_record.start_date
                 else
                   true
                 end
               else
                 false
               end
      previous_induction_record = induction_record
      result
    end
  end

  def is_not_induction_completed?
    ecf1_teacher_history.ect&.induction_completion_date.blank?
  end

  def has_not_been_withdrawn_or_deferred?
    ecf1_teacher_history.ect&.induction_records&.none? { |ir| ir.training_status.in? %w[withdrawn deferred] } &&
      ecf1_teacher_history.mentor&.induction_records&.none? { |ir| ir.training_status.in? %w[withdrawn deferred] }
  end

  def below_threshold_for_induction_records
    mentor_induction_records_count <= 2 && ect_induction_records_count <= 2
  end

  def ect_induction_records_count
    ecf1_teacher_history.ect&.induction_records&.count || 0
  end

  def mentor_induction_records_count
    ecf1_teacher_history.mentor&.induction_records&.count || 0
  end
end
