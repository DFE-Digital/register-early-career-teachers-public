module Migration
  class Milestone < Migration::Base
    belongs_to :schedule
  end
end
