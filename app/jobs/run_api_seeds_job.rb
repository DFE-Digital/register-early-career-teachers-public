class RunAPISeedsJob < ApplicationJob
  queue_as :api_seeds

  # This job runs when spinning up a review app/reseeding staging and it's
  # not suitable for retrying as it requires a clean database to run successfully.
  retry_on StandardError, attempts: 1

  def perform
    return if Rails.env.production?

    Rails.application.load_tasks

    Rake::Task["api_seed_data:generate"].invoke
  end
end
