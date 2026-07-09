module Periods
  module Transferable
    extend ActiveSupport::Concern

    included do
      attr_reader :period, :target_school
    end

    class_methods do
      def call(**args)
        new(**args).call
      end
    end

    def initialize(period:, target_school:)
      @period = period
      @target_school = target_school
    end

    def call
      prepare

      ActiveRecord::Base.transaction do
        update_related_records!

        period.save!
      end
    end

  private

    def prepare
      update_training_periods
      update_events

      period.assign_attributes(school: target_school)
    end

    def update_related_records!
      training_periods.each(&:save!)
      events.each(&:save!)
    end

    def update_training_periods
      training_periods.each do |training_period|
        training_period.school_partnership = new_partnership_for(training_period)
      end
    end

    def update_events
      events.each do |event|
        event.school_partnership = new_partnership_for(event)
        event.school = target_school if event.school.present?
      end
    end

    def new_partnership_for(object)
      GIAS::Schools::SchoolPartnerships::Transfer.call(object:, period_type:, target_school:)
    end

    def period_type
      raise NotImplementedError
    end

    delegate :training_periods, to: :period
    delegate :events, to: :period
    delegate :mentorship_periods, to: :period
  end
end
