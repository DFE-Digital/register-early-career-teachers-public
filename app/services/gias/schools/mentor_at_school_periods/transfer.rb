module GIAS
  module Schools
    module MentorAtSchoolPeriods
      class Transfer
        attr_reader :period, :target_school

        def initialize(period:, target_school:)
          @period = period
          @target_school = target_school
        end

        def self.call(...) = new(...).call

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
          update_mentorship_periods
          update_events

          period.assign_attributes(school: target_school)
        end

        def update_related_records!
          training_periods.each(&:save!)
          events.each(&:save!)

          mentorship_periods.each do |mentorship_period|
            mentorship_period.mentee.save!
            mentorship_period.save!
          end
        end

        def update_mentorship_periods
          mentorship_periods.each do |mentorship_period|
            GIAS::Schools::ECTAtSchoolPeriods::Transfer.call(period: mentorship_period.mentee, target_school:)
          end
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

        def period_type = :mentor_at_school_period

        delegate :training_periods, to: :period
        delegate :events, to: :period
        delegate :mentorship_periods, to: :period
      end
    end
  end
end

