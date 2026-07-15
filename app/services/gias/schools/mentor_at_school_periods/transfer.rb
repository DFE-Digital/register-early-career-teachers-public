module GIAS
  module Schools
    module MentorAtSchoolPeriods
      class Transfer
        attr_reader :mentor_at_school_period, :predecessor_school, :successor_school

        def initialize(mentor_at_school_period:, predecessor_school:, successor_school:)
          @mentor_at_school_period = mentor_at_school_period
          @successor_school = successor_school
          @predecessor_school = predecessor_school
        end

        def self.call(**args) = new(**args).call

        def call
          return unless predecessor_school == mentor_at_school_period.school

          ActiveRecord::Base.transaction do
            update_events!
            assign_training_periods

            mentor_at_school_period.assign_attributes(school: successor_school)

            training_periods.each(&:save!)

            mentorship_periods.each do |mentorship_period|
              GIAS::Schools::ECTAtSchoolPeriods::Transfer.call(ect_at_school_period: mentorship_period.mentee, predecessor_school:, successor_school:)
            end

            mentor_at_school_period.save!

            record_event!
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

        def record_event!
          Events::Record.record_teacher_mentor_at_school_period_moved_school!(
            teacher:,
            mentor_at_school_period:,
            old_school_name: predecessor_gias_school.name,
            new_school: successor_school,
            happened_at: predecessor_gias_school.closed_on,
            author: Events::SystemAuthor.new
          )
        end

        def predecessor_gias_school = predecessor_school.gias_school

        delegate :mentorship_periods, :training_periods, :events, :teacher, to: :mentor_at_school_period
      end
    end
  end
end
