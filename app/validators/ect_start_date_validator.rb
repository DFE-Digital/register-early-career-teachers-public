class ECTStartDateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    start_date = Schools::Validation::ECTStartDate.new(value)

    unless start_date.valid?
      record.errors.add(attribute, start_date.format_error)
    end
  end
end
