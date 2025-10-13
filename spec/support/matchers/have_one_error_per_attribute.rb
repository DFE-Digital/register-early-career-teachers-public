RSpec::Matchers.define :have_one_error_per_attribute do
  match do |actual|
    actual.valid?
    @errors_hash = actual.errors.to_hash(true)
    @multiple_errors = @errors_hash.select { |_attr, messages| messages.size > 1 }
    @multiple_errors.empty?
  end

  failure_message do |_actual|
    "expected each attribute to have exactly one error, but found:\n" +
      @multiple_errors.map { |attr, messages| "#{attr}: #{messages.size} errors (#{messages.join(', ')})" }.join("\n")
  end

  failure_message_when_negated do |_actual|
    "expected exactly one error message per attribute, but have more"
  end

  description do
    "have exactly one error message per attribute"
  end
end
