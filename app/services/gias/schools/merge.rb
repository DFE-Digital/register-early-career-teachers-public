module GIAS::Schools
  class Merge
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
            GIAS::Schools::MentorAtSchoolPeriods::Merge.call(periods:, target_school:)
          end
        end

        school.mentor_at_school_periods.reload.each do |period|
          GIAS::Schools::MentorAtSchoolPeriods::Transfer.move!(period:, target_school:)
        end

        school.ect_at_school_periods.reload.each do |period|
          GIAS::Schools::ECTAtSchoolPeriods::Transfer.move!(period:, target_school:)
        end

        record_school_merged_event!
      end
    end

    def overlapping_mentor_at_school_periods(teacher)
      GIAS::Schools::MentorAtSchoolPeriods::Overlapping.find(teacher:, schools:)
    end

    def record_school_merged_event!
      # TODO
    end

    def author
      Events::SystemAuthor.new
    end

    def schools = [school, target_school]
    def target_school = successor.school

    delegate :successor, to: :gias_school
    delegate :school, to: :gias_school
    delegate :mentor_teachers, to: :school, prefix: false

    def remaining_at_school_periods
      school.mentor_at_school_periods + school.ect_at_school_periods
    end
  end
end
