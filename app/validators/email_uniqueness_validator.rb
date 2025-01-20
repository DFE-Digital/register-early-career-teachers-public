class EmailUniquenessValidator < ActiveModel::Validator
  def validate(record)
    return if record.email.blank?

    # Check for conflicting records with the same email but different teacher_id
    conflicting_period = ECTAtSchoolPeriod
                           .where(email: record.email)
                           .where.not(teacher_id: record.teacher_id)
                           .where.not(id: record.id)
                           .exists?

    if conflicting_period
      record.errors.add(:email, "Email address is already in use by another teacher")
    end
  end
end
