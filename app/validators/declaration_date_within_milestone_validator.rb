class DeclarationDateWithinMilestoneValidator < ActiveModel::Validator
  def validate(record)
    declaration_within_milestone(record)
  end

private

  def declaration_within_milestone(record)
    return if record.errors[:declaration_date].any?

    return unless record.milestone && record.declaration_date.present?

    if record.declaration_date < record.milestone.start_date.beginning_of_day
      record.errors.add(:declaration_date, "Declaration date must be on or after the milestone start date for the same declaration type.")
    end

    if record.milestone.milestone_date.present? && (record.milestone.milestone_date.end_of_day <= record.declaration_date)
      record.errors.add(:declaration_date, "Declaration date must be on or before the milestone date for the same declaration type.")
    end
  end
end
