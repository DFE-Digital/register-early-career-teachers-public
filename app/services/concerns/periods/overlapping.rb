module Periods
  module Overlapping
    extend ActiveSupport::Concern

    class_methods do
      def find(...) = new(...).find
    end

    def find
      @groups = []

      group_periods

      groups.select(&:many?)
    end

  private

    attr_reader :groups

    def ordered_periods
      periods.sort_by(&:started_on)
    end

    def group_periods = group_by_order

    def group_by_order(periods = ordered_periods)
      periods.each do |period|
        if start_new_group?(groups.last, period)
          groups << [period]
        else
          groups.last << period
        end
      end
    end

    def start_new_group?(current_group, next_period)
      return true if current_group.nil?

      gap_between?(current_group, next_period)
    end

    def gap_between?(group, period)
      return false if group.any?(&:unfinished?)

      group.map(&:finished_on).max < period.started_on
    end
  end
end
