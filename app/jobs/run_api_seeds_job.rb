class RunAPISeedsJob < ApplicationJob
  queue_as :api_seeds

  def perform
    return if Rails.env.production?

    Rails.application.load_tasks

    Rake::Task["api_seed_data:generate"].invoke
  end
end
