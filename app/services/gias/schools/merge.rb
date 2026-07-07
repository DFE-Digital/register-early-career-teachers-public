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

        school.mentor_at_school_periods.reload.each do |period|
          GIAS::Schools::Merge::Period.move!(period:, school: successor.school)
        end

        school.ect_at_school_periods.reload.each do |period|
          GIAS::Schools::Merge::Period.move!(period:, school: successor.school)
        end

        record_school_merged_event!
      end
    end

    def overlapping_mentor_at_school_periods(teacher)
      GIAS::Schools::Merge::OverlappingMentorAtSchoolPeriods.find(teacher:, schools:)
    end

    def reassignment_required?(object, period_type)
      return false unless object.respond_to?(period_type) && object.respond_to?(:school_partnership)

      at_school_period = object.send(period_type)
      return false if at_school_period.nil?

      (at_school_period.school != new_school) && object.school_partnership.present?
    end

    def new_partnership_for(object)
      return unless object.respond_to?(:school_partnership) && object.school_partnership.present?

      GIAS::Schools::Merge::SchoolPartnerships.resolve!(
        existing_school_partnership: object.school_partnership,
        school_without_partnership: new_school
      )
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
