module GIAS::Reconciliation
  class Merge
    def self.merge!(gias_school) = new(gias_school).merge!

    def initialize(gias_school)
      @gias_school = gias_school
    end

    def merge!
      return false unless eligibility.can_be_merged?

      ActiveRecord::Base.transaction do
        ensure_successor_school_exists!

        mentor_teachers.each do |teacher|
          overlapping_mentor_at_school_periods(teacher).each do |periods|
            MentorAtSchoolPeriods::Merge.call(periods:, predecessor_school:, successor_school:)
          end
        end

        remaining_mentor_periods = predecessor_school.mentor_at_school_periods.reload

        remaining_mentor_periods.each do |mentor_at_school_period|
          MentorAtSchoolPeriods::Transfer.call(mentor_at_school_period:, predecessor_school:, successor_school:)
        end

        remaining_ect_periods = predecessor_school.ect_at_school_periods.reload

        remaining_ect_periods.each do |ect_at_school_period|
          ECTAtSchoolPeriods::Transfer.call(ect_at_school_period:, predecessor_school:, successor_school:)
        end

        predecessor_school.events.each(&:destroy!)
        predecessor_school.school_partnerships.each(&:destroy!)
        predecessor_school.destroy!

        record_school_merged_event!
      end

      true
    end

  private

    attr_reader :gias_school

    def eligibility
      @eligibility ||= GIAS::Reconciliation::Eligibility.new(gias_school)
    end

    def ensure_successor_school_exists!
      return if successor.school.present?

      successor.create_school!
      record_successor_school_opened_event!
    end

    def overlapping_mentor_at_school_periods(teacher)
      MentorAtSchoolPeriods::Overlapping.find(
        teacher:,
        schools: [predecessor_school, successor_school]
      )
    end

    def record_school_merged_event!
      Events::Record.record_school_merged_event!(
        school: successor_school,
        successor_gias_school: successor,
        predecessor_gias_school: gias_school,
        happened_at: closed_on,
        author:
      )
    end

    def record_successor_school_opened_event!
      Events::Record.record_school_opened_event!(
        school: successor.school,
        gias_school: successor,
        happened_at: closed_on,
        author:
      )
    end

    def predecessor_school = school
    def successor_school = @successor_school ||= successor.school

    delegate :school, :closed_on, :successor, to: :gias_school
    delegate :mentor_teachers, to: :school, prefix: false

    def author = Events::SystemAuthor.new
  end
end
