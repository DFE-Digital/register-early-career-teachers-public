class EvidencedAtWithinMilestoneValidator < ActiveModel::Validator
  def validate(record)
    declaration_within_milestone(record)
  end

private

  def declaration_within_milestone(record)
    return if record.errors[:evidenced_at].any?
    return if record.errors[:declaration_type].any?
    return if record.errors[:contract_period_year].any?

    return unless record.milestone && record.evidenced_at.present?

    if record.evidenced_at < record.milestone.start_date.beginning_of_day
      record.errors.add(:evidenced_at, "Evidenced at must be on or after the milestone start date for the same declaration type.")
    end

    if record.milestone.milestone_date.present? && (record.milestone.milestone_date.end_of_day <= record.evidenced_at)
      record.errors.add(:evidenced_at, "Evidenced at must be on or before the milestone date for the same declaration type.")
    end
  end

  def validation_context(record)
    return record.validation_context[:context]&.to_sym if record.validation_context.respond_to?(:dig)
    return record.validation_context.to_sym if record.validation_context.respond_to?(:to_sym)

    record.validation_context
  end
end
