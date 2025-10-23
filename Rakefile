# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"

# Workaround for https://github.com/rswag/rswag/issues/359
# Reason we need it https://github.com/rswag/rswag/blob/master/README.md?plain=1#L811-L833
if defined? RSpec
  RSpec.configure do |config|
    config.rswag_dry_run = false
  end
end

Rails.application.load_tasks
