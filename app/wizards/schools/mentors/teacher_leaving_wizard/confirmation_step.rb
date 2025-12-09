module Schools
  module Mentors
    module TeacherLeavingWizard
      class ConfirmationStep < Mentors::Step
        def leaving_date
          value = store.leaving_on
          return mentor_at_school_period.finished_on if value.blank?

          Schools::Validation::LeavingDate.new(date_as_hash: value).value_as_date
        end

        def leaving_today_or_in_future?
          return unless leaving_date

          leaving_date >= Time.zone.today
        end

        def teacher_full_name
          name_for(mentor_at_school_period.teacher)
        end

        def heading_title
          if leaving_today_or_in_future?
            "#{teacher_full_name} will be removed from your school’s mentor list after #{leaving_date.to_fs(:govuk)}"
          else
            "#{teacher_full_name} has been removed from your school’s mentor list"
          end
        end

        def assigned_ects_message
          "ECTs currently assigned to #{teacher_full_name} will need to be reassigned to another mentor."
        end

        def training_heading
          return unless leaving_today_or_in_future?

          "If #{teacher_full_name} is doing mentor training"
        end

        def training_message
          return unless leaving_today_or_in_future?

          "They should continue with their current training programme until their leaving date."
        end

        def notification_message
          if leaving_today_or_in_future?
            "We’ll let their lead provider know that you’ve told us that they’re leaving your school and are not expected to return. They may contact your school for more information."
          else
            "We’ll let #{teacher_full_name}’s lead provider know (if they were doing a mentor training programme) that you’ve told us that they’ve left your school and are not expected to return. They may contact your school for more information."
          end
        end
      end
    end
  end
end
