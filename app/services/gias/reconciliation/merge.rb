module GIAS::Reconciliation
  class Merge
    def self.merge!(gias_school, refresh_metadata: true) = new(gias_school, refresh_metadata:).merge!

    def initialize(gias_school, refresh_metadata: true)
      @gias_school = gias_school
      @refresh_metadata = refresh_metadata
    end

    def merge!
      return false unless eligibility.can_be_merged?

      teachers_to_refresh = affected_teachers

      DeclarativeUpdates.skip(:metadata) do
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

          destroy_predecessor_school_events!
          destroy_predecessor_school_partnerships!
          destroy_predecessor_school_metadata!
          destroy_predecessor_school!

          record_school_merged_event!
        end
      end

      refresh_school_metadata!
      refresh_teacher_metadata!(teachers_to_refresh)

      true
    end

  private

    attr_reader :gias_school, :refresh_metadata

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

    def destroy_predecessor_school_partnerships!
      predecessor_school.school_partnerships.destroy_all
    end

    def destroy_predecessor_school_metadata!
      Metadata::SchoolContractPeriod.where(school_id: predecessor_school.id).delete_all
      Metadata::SchoolLeadProviderContractPeriod.where(school_id: predecessor_school.id).delete_all
    end

    def destroy_predecessor_school_events!
      predecessor_school.events.destroy_all
    end

    def destroy_predecessor_school!
      predecessor_school.destroy!
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

    def affected_teachers
      return unless refresh_metadata

      @affected_teachers ||= (mentor_teachers + ect_teachers).uniq
    end

    def refresh_school_metadata!
      return unless refresh_metadata

      Metadata::Handlers::School.new(successor_school).refresh_metadata!
    end

    def refresh_teacher_metadata!(teachers)
      return unless refresh_metadata

      teachers.each do |teacher|
        Metadata::Handlers::Teacher.new(teacher).refresh_metadata!
      end
    end

    def predecessor_school = school
    def successor_school = @successor_school ||= successor.school

    delegate :school, :closed_on, :successor, to: :gias_school
    delegate :mentor_teachers, :ect_teachers, to: :school, prefix: false

    def author = Events::SystemAuthor.new
  end
end
