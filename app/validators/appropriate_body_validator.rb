class AppropriateBodyValidator < ActiveModel::Validator
  def validate(record)
    must_be_present(record)
    cannot_be_local_authority(record) if record.appropriate_body
    must_be_school_teaching_hub(record) if record.school&.state_funded? && record.appropriate_body
  end

  def must_be_present(record)
    return if record.appropriate_body

    record.errors.add(:appropriate_body, "Select the appropriate body which will be supporting the ECT's induction")
  end

  def cannot_be_local_authority(record)
    return unless record.appropriate_body.local_authority?

    record.errors.add(:appropriate_body, "Select a valid appropriate body which will be supporting the ECT's induction")
  end

  def must_be_school_teaching_hub(record)
    return if record.appropriate_body.teaching_school_hub?

    record.errors.add(:appropriate_body, "Select a teaching school hub appropriate body which will be supporting the ECT's induction")
  end
end
