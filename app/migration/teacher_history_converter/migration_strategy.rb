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
    [
      has_not_completed_induction?,
      dates_are_in_the_right_order_for?(ecf1_teacher_history.ect&.induction_records),
      dates_are_in_the_right_order_for?(ecf1_teacher_history.mentor&.induction_records),
      (below_threshold_for_induction_records || !any_induction_records_overlap?)
    ].all?
  end

  def any_induction_records_overlap?
    [
      has_overlaps?(ecf1_teacher_history.mentor&.induction_records),
      has_overlaps?(ecf1_teacher_history.ect&.induction_records)
    ].any?
  end

  def dates_are_in_the_right_order_for?(induction_records)
    return true if induction_records.blank?

    induction_records.all?(&:dates_in_order?)
  end

  def has_completed_induction?
    ecf1_teacher_history.ect.present? && ecf1_teacher_history.ect.induction_completion_date.present?
  end

  def has_not_completed_induction?
    !has_completed_induction?
  end

  def has_not_been_withdrawn_or_deferred?
    !(withdrawn_or_deferred?(ecf1_teacher_history.ect) || withdrawn_or_deferred?(ecf1_teacher_history.mentor))
  end

  def withdrawn_or_deferred?(profile)
    return false unless profile.present? && profile.induction_records.present?

    profile.induction_records.any? { |ir| ir.training_status.in? %w[withdrawn deferred] }
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

  def has_overlaps?(induction_records)
    return false if induction_records.blank?

    induction_records
      .map { it.start_date...it.end_date }
      .each_cons(2)
      .any? { |a, b| a.overlap?(b) }
  end
end
