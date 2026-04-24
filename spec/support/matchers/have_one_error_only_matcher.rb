RSpec::Matchers.define :have_one_error_only do
  match do |actual|
    actual.invalid? && actual.errors.count == 1
  end

  failure_message do |_actual|
    "expected #{actual.class} to have 1 error, but it had #{actual.errors.count} with messages: #{actual.errors.full_messages.join("\n")}"
  end

  failure_message_when_negated do |_actual|
    "expected exactly one error message in total, but found more"
  end

  description do
    "have exactly one error message in total across all attributes"
  end
end
