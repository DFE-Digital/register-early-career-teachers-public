module Admin
  module Teachers
    module UndoRegistrationWizard
      class MentorshipPeriodsSummaryComponent < ApplicationComponent
        include TeacherHelper

        attr_reader :mentorship_periods, :school_period

        def initialize(mentorship_periods:, school_period:, end_date_for:)
          @mentorship_periods = mentorship_periods
          @school_period = school_period
          @end_date_for = end_date_for
        end

        def call
          govuk_table do |table|
            table.with_head do |head|
              head.with_row do |row|
                row.with_cell(text: "Name")
                row.with_cell(text: "Start date")
                row.with_cell(text: "End date")
              end
            end

            table.with_body do |body|
              mentorship_periods.each do |mentorship_period|
                body.with_row do |row|
                  row.with_cell(
                    text: teacher_full_name(related_teacher(mentorship_period)),
                    header: true
                  )
                  row.with_cell(text: mentorship_period.started_on.to_fs(:govuk))
                  row.with_cell(text: end_date_for(mentorship_period)&.to_fs(:govuk) || "Present")
                end
              end
            end
          end
        end

      private

        def related_teacher(mentorship_period)
          case school_period
          when ECTAtSchoolPeriod
            mentorship_period.mentor.teacher
          when MentorAtSchoolPeriod
            mentorship_period.mentee.teacher
          else
            raise ArgumentError, "Unsupported school period: #{school_period.class.name}"
          end
        end

        def end_date_for(mentorship_period)
          @end_date_for.call(mentorship_period)
        end
      end
    end
  end
end
