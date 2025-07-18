module Builders
  class MentorshipPeriods
    attr_reader :teacher, :mentorship_period_data

    def initialize(teacher:, mentorship_period_data:)
      @teacher = teacher
      @mentorship_period_data = mentorship_period_data
    end

    def build
      period_date = Data.define(:started_on, :finished_on)
      success = true

      mentorship_period_data.each do |period|
        period_dates = period_date.new(started_on: period.start_date, finished_on: period.end_date)
        teacher_period = teacher.ect_at_school_periods.containing_period(period_dates).first

        if teacher_period.nil?
          log_period_error(period:, message: "No ECTAtSchoolPeriod found for mentorship dates")
          success = false
          next
        end

        if period.mentor_teacher.nil?
          log_period_error(period:, message: "Mentor not found in migrated data")
          success = false
          next
        end

        mentor_period = period.mentor_teacher.mentor_at_school_periods
          .where(school_id: teacher_period.school_id)
          .containing_period(period_dates).first

        if mentor_period.nil?
          log_period_error(period:, message: "No MentorAtSchoolPeriod found for mentorship dates")
          success = false
          next
        end

        mentorship_period = ::MentorshipPeriod.find_or_initialize_by(mentee: teacher_period, started_on: period.start_date)
        mentorship_period.mentor = mentor_period
        mentorship_period.finished_on = period.end_date
        mentorship_period.ecf_start_induction_record_id = period.start_source_id
        mentorship_period.ecf_end_induction_record_id = period.end_source_id
        mentorship_period.save!
      rescue ActiveRecord::ActiveRecordError => e
        log_period_error(period:, message: e.message)
        success = false
      end

      success
    end

  private

    def log_period_error(period:, message:)
      ::TeacherMigrationFailure.create!(teacher:,
                                        model: :mentorship_period,
                                        message:,
                                        migration_item_id: period.start_source_id,
                                        migration_item_type: "Migration::InductionRecord")
    end
  end
end
