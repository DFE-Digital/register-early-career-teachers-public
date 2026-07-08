module GIAS
  module Schools
    class Merge
      class Period

        attr_reader :period, :school

        def initialize(period:, school:)
          @period = period
          @school = school
        end

        def self.move!(...) = new(...).move!
        def self.prepare(...) = new(...).prepare

        def prepare
          update_training_periods
          update_mentorship_periods
          update_events

          period.assign_attributes(school:)
        end

        def move!
          prepare 
          
          ActiveRecord::Base.transaction do
            training_periods.each(&:save!)
            events.each(&:save!)

            mentorship_periods.each do |mentorship_period|
              mentorship_period.mentee.save!
              mentorship_period.save!
            end

            period.save!
          end
        end

        private

        def update_mentorship_periods
          return unless period_type == :mentor_at_school_period

          mentorship_periods.each do |mentorship_period|
            GIAS::Schools::Merge::Period.move(period: mentorship_period.mentee, school:)
          end
        end

        def update_training_periods
          training_periods.each do |training_period|
            training_period.school_partnership = new_partnership_for(training_period) if reassignment_required?(training_period, period_type)
          end
        end

        def update_events
          events.each do |event|
            event.school_partnership = new_partnership_for(event) if reassignment_required?(event, :period)
            event.school = school if event.school.present?
          end
        end

        def reassignment_required?(object, period_type)
          return false unless object.respond_to?(period_type) && object.respond_to?(:school_partnership)

          at_school_period = object.send(period_type)
          return false if at_school_period.nil?

          (at_school_period.school != school) && object.school_partnership.present?
        end

        def new_partnership_for(object)
          return unless object.respond_to?(:school_partnership) && object.school_partnership.present?

          GIAS::Schools::Merge::SchoolPartnerships.resolve!(
            existing_school_partnership: object.school_partnership,
            school_without_partnership: school
          )
        end

        def period_type
          case period
          when ECTAtSchoolPeriod
            :ect_at_school_period
          when MentorAtSchoolPeriod
            :mentor_at_school_period
          else
            raise ArgumentError, "Unsupported period type: #{period.class.name}"
          end
        end

        delegate :training_periods, to: :period
        delegate :events, to: :period
        delegate :mentorship_periods, to: :period
      end
    end
  end
end

