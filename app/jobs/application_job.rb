class ApplicationJob < ActiveJob::Base
  # Will retry with an polynomial backoff for approximately 24 hours before failing.
  # See https://api.rubyonrails.org/v8.0/classes/ActiveJob/Exceptions/ClassMethods.html#method-i-retry_on
  retry_on StandardError, wait: :polynomially_longer, attempts: 14

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end
