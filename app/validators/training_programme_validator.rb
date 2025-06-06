class TrainingProgrammeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.blank?
      record.errors.add(attribute, "Select either 'Provider-led' or 'School-led' training")
    elsif !::TRAINING_PROGRAMME.key?(value.to_sym)
      record.errors.add(attribute, "'#{value}' is not a valid programme type")
    end
  end
end
