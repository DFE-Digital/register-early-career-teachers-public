class ECTStartDateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    start_date = Schools::Validation::ECTStartDate.new(
      ect_start_date_as_hash: value,
      current_date: options[:current_date]
    )

    unless start_date.valid?
      record.errors.add(attribute, start_date.format_error)
    end
  end
end