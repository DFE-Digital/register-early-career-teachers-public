class RecurringJob < ApplicationJob
  # As recurring jobs re-run on a schedule, we don't want to retry them.
  retry_on StandardError, attempts: 1
end
