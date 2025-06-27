module SequentialInterval
  extend ActiveSupport::Concern

  included { include Queries::RangeQueries }

  class_methods do
    def current_on(date)
      find_by(*date_in_range(date))
    end
  end
end
