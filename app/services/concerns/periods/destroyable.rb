module Periods
  module Destroyable
    extend ActiveSupport::Concern

    included do
      attr_reader :period, :author
    end

    class_methods do
      def call(**args)
        new(**args).call
      end
    end

    def call
      return unless period
      return if period_started?

      ActiveRecord::Base.transaction do
        record_unstarted_period_deleted_event!
        destroy_mentorship_period_events!
        destroy_training_period_events!
        destroy_period_events!
        period.destroy!
      end
    end

  private

    def period_started?
      started_on < Time.zone.today
    end

    def destroy_mentorship_period_events!
      mentorship_periods.each do |mentorship_period|
        mentorship_period.events.each(&:destroy!)
      end
    end

    def destroy_training_period_events!
      training_periods.each do |training_period|
        training_period.events.each(&:destroy!)
      end
    end

    def destroy_period_events!
      period.events.each(&:destroy!)
    end

    def record_unstarted_period_deleted_event!
      raise NotImplementedError
    end

    delegate :started_on, :school, :teacher, :training_periods, :mentorship_periods, to: :period
  end
end
