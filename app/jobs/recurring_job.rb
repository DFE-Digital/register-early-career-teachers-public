class RecurringJob < ApplicationJob
  # As recurring jobs re-run on a schedule, we don't want to retry them.
  retry_on Exception, attempts: 1
end
