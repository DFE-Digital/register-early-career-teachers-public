module APISeedDataHelpers
  # Runs API seed planters outside of per-example stubs, e.g. in `before_all`
  # blocks: seed services only plant in certain environments (see
  # APISeedData::Base#plantable?) and log to $stdout, and RSpec mocks are not
  # available outside of examples, so we swap the real Rails.env and $stdout
  # around the plant calls instead.
  def plant_api_seed_support_data(*planter_classes)
    original_env = Rails.env
    original_stdout = $stdout

    Rails.env = "sandbox"
    $stdout = File.open(File::NULL, "w")

    planter_classes.each { |planter_class| planter_class.new.plant }
  ensure
    $stdout = original_stdout
    Rails.env = original_env
  end
end

RSpec.configure do |config|
  config.include APISeedDataHelpers
end
