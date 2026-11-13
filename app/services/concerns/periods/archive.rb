module Periods
  module Archive
    extend ActiveSupport::Concern

    class_methods do
      def call(period) = new(period).call

      def period_class
        raise NotImplementedError, "Archive services must define their period class"
      end
    end

    def initialize(period)
      @period = period
    end

    def call
      return if period.archived?

      ActiveRecord::Base.transaction do
        archive_associated_periods!
        period.archive!
        record_archive_event!
      end
    end

  private

    attr_reader :period, :author, :happened_at

    def archive_associated_periods!
      if period.respond_to?(:mentorship_periods)
        period.mentorship_periods.each { MentorshipPeriods::Archive.call(it) }
      end

      if period.respond_to?(:training_periods)
        period.training_periods.each { TrainingPeriods::Archive.call(it) }
      end
    end

    def record_archive_event!
      # TODO
    end
  end
end
