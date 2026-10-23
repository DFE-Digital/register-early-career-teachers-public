module Admin
  module Teachers
    module ChangeTRNWizard
      class Wizard < ApplicationWizard
        attr_accessor :store, :teacher_id, :author

        steps do
          [{
            enter_trn: EnterTRNStep,
            merge_preview: MergePreviewStep,
            confirm_merge: ConfirmMergeStep,
            records_merged: RecordsMergedStep,
            confirm: ConfirmStep,
            confirmation: ConfirmationStep
          }]
        end

        def self.step?(step_name)
          steps.first[step_name].present?
        end

        def allowed_steps
          return [:records_merged] if store.records_merged
          return [:confirmation] if store.trn_replaced
          return [] unless teacher.trs_response_gone?

          allowed = [:enter_trn]
          return allowed if store.trn.blank?

          if store.destination_teacher_id.present?
            allowed.concat(%i[merge_preview confirm_merge])
          else
            allowed << :confirm
          end

          allowed
        end

        def teacher
          @teacher ||= Teacher.find(teacher_id)
        end

        def teacher_name
          return store.source_teacher_name if store.records_merged

          ::Teachers::Name.new(teacher).full_name
        end

        def destination
          return if store.destination_teacher_id.blank?

          @destination ||= Teacher
            .where.not(id: teacher_id)
            .find_by!(
              id: store.destination_teacher_id,
              trn: store.trn
            )
        end

        def replace_trn!
          old_trn = teacher.trn

          ::Teachers::ReplaceTRN.new(
            teacher:,
            author:
          ).replace_deactivated!(new_trn: store.trn)

          store.old_trn = old_trn
        end

        def merge_trn!
          destination_teacher = destination
          source_teacher_name = teacher_name
          destination_teacher_name = ::Teachers::Name
            .new(destination_teacher)
            .full_name

          ::Teachers::MergeTRN.new(teacher:).merge_deactivated!(
            destination: destination_teacher,
            author:
          )

          store.old_trn = teacher.trn
          store.source_teacher_name = source_teacher_name
          store.destination_teacher_name = destination_teacher_name
        end

        def allowed_step_path
          return teacher_overview_path if allowed_steps.empty?

          step_path(allowed_steps.last)
        end

        def current_step_path
          step_path(current_step_name)
        end

        def next_step_path
          step_path(current_step.next_step)
        end

        def previous_step_path
          step_path(current_step.previous_step)
        end

      private

        def teacher_overview_path
          Rails.application.routes.url_helpers.admin_teacher_path(teacher)
        end

        def step_path(step_name)
          return if step_name.blank?

          Rails.application.routes.url_helpers.public_send(
            "admin_teacher_change_trn_wizard_#{step_name}_path",
            teacher_id
          )
        end
      end
    end
  end
end
