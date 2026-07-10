module Periods
  module Transferable
    extend ActiveSupport::Concern

    included do
      attr_reader :period, :predecessor_school, :successor_school
    end

    class_methods do
      def call(**args)
        new(**args).call
      end
    end

    def initialize(period:, predecessor_school:, successor_school:)
      @period = period
      @successor_school = successor_school
      @predecessor_school = predecessor_school
    end

    def call
      return unless predecessor_school == period.school

      ActiveRecord::Base.transaction do
        update_events!
        assign_training_periods

        period.assign_attributes(school: successor_school)

        training_periods.each(&:save!)

        period.save!
      end
    end

  private

    def assign_training_periods
      training_periods.each do |training_period|
        new_partnership = new_partnership_for(training_period)
        training_period.school_partnership = new_partnership if new_partnership
      end
    end

    def update_events!
      events.each do |event|
        new_partnership = new_partnership_for(event)
        event.school_partnership = new_partnership if new_partnership
        event.school = successor_school if event.school.present?
        event.save!
      end
    end

    def new_partnership_for(object)
      GIAS::Schools::SchoolPartnerships::Transfer.call(object:, successor_school:)
    end

    delegate :training_periods, to: :period
    delegate :events, to: :period
    delegate :mentorship_periods, to: :period
  end
end
