module Schools
  module ECTs
    module TeacherLeavingWizard
      class CheckAnswersStep < ECTs::Step
        attr_accessor :leaving_on

        def previous_step = :edit

        def next_step = :confirmation

        def leaving_date
          return if leaving_on.blank?

          Schools::Validation::LeavingDate
            .new(date_as_hash: leaving_on)
            .value_as_date
        end

        def save!
          date = leaving_date
          return false unless date

          report_teacher_leaving!(date)
          true
        end

        def leaving_today_or_in_future?
          return unless leaving_date

          leaving_date >= Time.zone.today
        end

        def heading_title
          "Confirm that #{teacher_full_name} #{leaving_today_or_in_future? ? 'is leaving' : 'has left'} your school permanently"
        end

        def leaving_statement
          "You’ve told us that #{teacher_full_name} #{leaving_today_or_in_future? ? 'is leaving' : 'left'} your school on #{leaving_date.to_fs(:govuk)}."
        end

        def teacher_full_name
          name_for(ect_at_school_period.teacher)
        end

        def edit_warning_statement
          suffix = leaving_today_or_in_future? ? " after #{leaving_date.to_fs(:govuk)}" : ""
          "You will not be able to view or edit #{teacher_full_name}’s details#{suffix}."
        end

      private

        def pre_populate_attributes
          self.leaving_on = store.leaving_on
        end

        def report_teacher_leaving!(finished_on)
          ECTAtSchoolPeriods::Finish.new(
            ect_at_school_period:,
            finished_on:,
            author:
          ).finish!
        end
      end
    end
  end
end
