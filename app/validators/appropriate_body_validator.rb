class AppropriateBodyValidator < ActiveModel::Validator
  # OPTIMIZE: Validate appropriate_body_id against a list of known appropriate bodies
  def validate(record)
    if record.appropriate_body_type.blank?
      record.errors.add(:appropriate_body_type, "Select the appropriate body which will be supporting the ECT's induction")
    end

    if record.appropriate_body_type == 'teaching_school_hub' && record.appropriate_body_id.blank?
      record.errors.add(:appropriate_body_id, "Enter the name of the appropriate body which will be supporting the ECT's induction")
    end
  end
end
