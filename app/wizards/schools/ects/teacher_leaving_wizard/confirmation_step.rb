module Schools
  module ECTs
    module TeacherLeavingWizard
      class ConfirmationStep < ECTs::Step
        def leaving_date
          value = store.leaving_on
          return ect_at_school_period.finished_on if value.blank?

          Schools::Validation::LeavingDate.new(date_as_hash: value).value_as_date
        end

        def leaving_in_future?
          return unless leaving_date

          leaving_date > Time.zone.today
        end

        def teacher_full_name
          name_for(ect_at_school_period.teacher)
        end

        def heading_title
          if leaving_in_future?
            "#{teacher_full_name} will be removed from your school’s ECT list after #{leaving_date.to_fs(:govuk)}"
          else
            "#{teacher_full_name} has been removed from your school’s ECT list"
          end
        end

        def training_message
          return unless leaving_in_future?

          "#{teacher_full_name} should continue with their current training programme until their leaving date."
        end

        def notification_message
          if leaving_in_future?
            "We’ll let their appropriate body and lead provider know (if they’re on a provider-led programme) that you’ve told us that they’re leaving your school and are not expected to return. They may contact your school for more information."
          else
            "We’ll let #{teacher_full_name}’s appropriate body and lead provider know (if they’re on a provider-led programme) that you’ve told us that they’ve left your school and are not expected to return. They may contact your school for more information."
          end
        end

        def mentor_training_message
          "#{teacher_full_name}’s mentor can continue their mentor training, even if they do not have other ECTs assigned to them."
        end
      end
    end
  end
end
