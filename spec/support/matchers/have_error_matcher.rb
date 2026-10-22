RSpec::Matchers.define :have_error do |attribute, message, context|
  match do |actual|
    actual.invalid?(context) && actual.errors.any? do |error|
      error_message_match = message.nil? || values_match?(message, error.message)

      error.attribute == attribute && error_message_match
    end
  end

  failure_message do |actual|
    expected = %(expected error on :#{attribute}#{message.nil? ? '' : %( with message #{message.inspect})})
    next "#{expected}, but there were no errors" if actual.errors.empty?

    actual.errors.map { |error|
      %(#{expected}, but got :#{error.attribute} with message "#{error.message}")
    }.join(" and ")
  end
end

RSpec::Matchers.define :have_no_error do |attribute, message, context|
  match do |actual|
    actual.valid?(context) || actual.errors.none? do |error|
      error_message_match = message.nil? || values_match?(message, error.message)

      error.attribute == attribute && error_message_match
    end
  end

  failure_message do |actual|
    matching_errors = actual.errors.select { |error| error.attribute == attribute }
    if message
      matching_errors = matching_errors.select { |error| values_match?(message, error.message) }
    end

    error_descriptions = matching_errors.map { |error| %("#{error.message}") }.join(", ")
    %(expected no error on :#{attribute}#{message ? %( with message #{message.inspect}) : ''}, but found: #{error_descriptions})
  end
end
