module Migration
  class Cohort < Migration::Base
    def next
      self.class.find_by(start_year: start_year + 1)
    end
  end
end
