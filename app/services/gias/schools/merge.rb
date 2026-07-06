module GIAS::Schools
  class Merge
    class NotImplemented < StandardError; end
    attr_reader :gias_school

    def initialize(gias_school)
      @gias_school = gias_school
    end

    def merge!
      return false unless gias_school.can_be_merged?

      merge_school!

      true
    end

  private

    def merge_school!
      ActiveRecord::Base.transaction do
        mentor_teachers.each do |teacher|
          overlapping_mentor_at_school_periods(teacher).each do |periods|
            target_period = periods.reverse.find { |period| period.school == successor.school }
            MentorAtSchoolPeriods.merge!(periods:, target_period:)
          end
        end

        remaining_at_school_periods.each do |period|
          period.update!(school: successor.school)
        end

        record_school_merged_event!
      end
    end

    def overlapping_mentor_at_school_periods(teacher)
      GIAS::Schools::Merge::OverlappingMentorAtSchoolPeriods.find(teacher:, schools:)
    end

    def record_school_merged_event!
      # TODO
    end

    def author
      Events::SystemAuthor.new
    end

    def new_school = successor.school

    def schools = [school, successor.school]

    delegate :successor, to: :gias_school
    delegate :school, to: :gias_school
    delegate :mentor_teachers, to: :school, prefix: false

    def remaining_at_school_periods
      school.mentor_at_school_periods + school.ect_at_school_periods
    end
  end
end
