class CorrectedNameValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    @corrected_name = Schools::Validation::CorrectedName.new(value)
    record.errors.add(attribute, error_message) unless @corrected_name.valid?
  end

private

  def error_message
    @corrected_name.error
  end
end
