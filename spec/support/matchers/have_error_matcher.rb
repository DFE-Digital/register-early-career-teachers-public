RSpec::Matchers.define :have_error do |attribute, message, context|
  match do |actual|
    actual.invalid?(context) && actual.errors.any? do |error|
      error_message_match = message.nil? || error.message == message

      error.attribute == attribute && error_message_match
    end
  end

  failure_message do |actual|
    actual.errors.map { |error|
      %(expected error on :#{attribute} with message "#{message}", but got :#{error.attribute} with message "#{error.message}")
    }.join(" and ")
  end
end
