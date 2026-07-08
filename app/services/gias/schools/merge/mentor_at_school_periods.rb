module GIAS
  module Schools
    class Merge
      class MentorAtSchoolPeriods
        class DifferentTeacher < StandardError; end
        class TargetNotIncluded < StandardError; end
        class StartAfterEnd < StandardError; end
        class MissingSchoolPartnership < StandardError; end

        attr_reader :periods,
                    :target_period

        def initialize(periods:, target_period:)
          @periods = periods
          @target_period = target_period
        end

        def self.merge!(...) = new(...).merge!

        def merge!
          prepare

          ActiveRecord::Base.transaction do
            training_periods.each(&:save!)
            events.each(&:save!)

            mentorship_periods.each do |mentorship_period|
              mentorship_period.mentee.save!
              mentorship_period.save!
            end

            redundant_periods.each do |period|
              period.training_periods.reset
              period.destroy!
            end

            target_period.save!
          end
        end

      private

        def prepare
          return unless valid?

          target_period.assign_attributes(started_on:, finished_on:)

          update_training_periods
          update_mentorship_periods
          update_events
        end

        def redundant_periods
          @redundant_periods ||= periods.excluding(target_period)
        end

        def training_periods
          @training_periods ||= redundant_periods.flat_map(&:training_periods).uniq
        end

        def mentorship_periods
          @mentorship_periods ||= redundant_periods.flat_map(&:mentorship_periods).uniq
        end

        def events
          @events ||= redundant_periods.flat_map(&:events).uniq
        end

        def update_training_periods
          training_periods.each do |training_period|
            training_period.school_partnership = new_partnership_for(training_period)
            training_period.mentor_at_school_period = target_period
          end
        end

        def update_mentorship_periods
          mentorship_periods.each do |mentorship_period|
            GIAS::Schools::Merge::Period.prepare(period: mentorship_period.mentee, school: target_school)
        
            mentorship_period.mentor = target_period
          end
        end

        def update_events
          events.each do |event|
            event.school_partnership = new_partnership_for(event)
            event.school = target_school if event.school.present?
            event.mentor_at_school_period = target_period
          end
        end

        def new_partnership_for(object)
          GIAS::Schools::Merge::SchoolPartnership.reassign!(object:, period_type: :mentor_at_school_period, target_school:)
        end

        def finished_on
          @finished_on ||= calculate_finished_on
        end

        def calculate_finished_on
          return nil if periods.any?(&:ongoing?)

          periods.map(&:finished_on).compact.max
        end

        def started_on
          @started_on ||= periods.map(&:started_on).min
        end

        def valid?
          target_included?
          belongs_to_same_teacher?
          start_before_end?

          true
        end

        def target_included?
          return if periods.include?(target_period)

          raise TargetNotIncluded, "Target period must be included in the periods being merged"
        end

        def start_before_end?
          return if finished_on.nil?
          return if started_on < finished_on

          raise StartAfterEnd, "Started on date must be before finished on date"
        end

        def belongs_to_same_teacher?
          return if periods.map(&:teacher_id).uniq.size == 1

          raise DifferentTeacher, "All periods must belong to the same teacher"
        end

        def target_school = target_period.school
      end
    end
  end
end
