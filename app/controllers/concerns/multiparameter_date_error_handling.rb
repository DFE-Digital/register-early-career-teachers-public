module MultiparameterDateErrorHandling
  extend ActiveSupport::Concern

private

  def add_multiparameter_date_errors(record, exception)
    raw_params = params[controller_name.singularize]

    exception.errors.each do |error|
      attribute = error.attribute
      day = raw_params["#{attribute}(3i)"]
      month = raw_params["#{attribute}(2i)"]
      year = raw_params["#{attribute}(1i)"]
      entered = "#{day}/#{month}/#{year}"

      record.errors.add(attribute, "#{entered} is not a valid date")
    end
  end
end
