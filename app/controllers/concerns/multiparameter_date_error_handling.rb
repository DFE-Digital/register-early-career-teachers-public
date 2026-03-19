module MultiparameterDateErrorHandling
  extend ActiveSupport::Concern

private

  def add_multiparameter_date_errors(record, exception)
    exception.errors.each do |error|
      attribute = error.attribute
      record.errors.add(attribute, "Enter the #{attribute.humanize.downcase} using the correct format, for example, 17 09 1999")
    end
  end
end
