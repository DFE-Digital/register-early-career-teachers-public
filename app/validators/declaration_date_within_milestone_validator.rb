class DeclarationDateWithinMilestoneValidator < ActiveModel::Validator
  def validate(record)
    declaration_within_milestone(record) unless being_migrated?(record)
  end

private

  def being_migrated?(record) = validation_context(record) == :being_migrated

  def declaration_within_milestone(record)
    return if record.errors[:declaration_date].any?
    return if record.errors[:declaration_type].any?

    return unless record.milestone && record.declaration_date.present?

    if record.declaration_date < record.milestone.start_date.beginning_of_day
      record.errors.add(:declaration_date, "Declaration date must be on or after the milestone start date for the same declaration type.")
    end

    if record.milestone.milestone_date.present? && (record.milestone.milestone_date.end_of_day <= record.declaration_date)
      record.errors.add(:declaration_date, "Declaration date must be on or before the milestone date for the same declaration type.")
    end
  end

  def validation_context(record)
    return record.validation_context[:context]&.to_sym if record.validation_context.respond_to?(:dig)
    return record.validation_context.to_sym if record.validation_context.respond_to?(:to_sym)

    record.validation_context
  end
end
