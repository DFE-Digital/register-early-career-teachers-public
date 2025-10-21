module Queries
  module FilterIgnorable
    extend ActiveSupport::Concern

    def ignore?(filter:, ignore_empty_array: true)
      return false if !ignore_empty_array && filter == []

      filter == :ignore || (!filter.nil? && filter.blank? && filter != false)
    end
  end
end
