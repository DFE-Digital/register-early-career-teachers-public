module Admin
  module Teachers
    module ChangeTRNWizard
      class Wizard < ApplicationWizard
        class TeacherNotDeactivatedError < StandardError; end
        class IneligibleForReplacementError < StandardError; end
        class IneligibleForMergeError < StandardError; end
        class MergeDestinationChangedError < StandardError; end

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
            allowed << :merge_preview
            allowed << :confirm_merge if store.merge_previewed
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
        rescue ActiveRecord::RecordNotFound
          raise MergeDestinationChangedError
        end

        def replace_trn!
          teacher.with_lock do
            raise TeacherNotDeactivatedError unless teacher.trs_response_gone?
            raise IneligibleForReplacementError unless ::Teachers::TRN::Eligibility
              .new(teacher:, new_trn: store.trn).can_be_replaced?

            old_trn = teacher.trn

            ::Teachers::TRN::Replace.new(teacher:, new_trn: store.trn, author:).replace!

            store.old_trn = old_trn
          end
        end

        def merge_trn!
          teacher.with_lock do
            destination.with_lock do
              raise TeacherNotDeactivatedError unless teacher.trs_response_gone?
              raise MergeDestinationChangedError unless destination.trn == store.trn
              raise IneligibleForMergeError unless ::Teachers::TRN::Eligibility
                .new(teacher:, new_trn: store.trn).can_be_merged?

              old_trn = teacher.trn
              source_teacher_name = teacher_name

              ::Teachers::TRN::Merge.new(teacher:, new_trn: store.trn, author:).merge!

              store.old_trn = old_trn
              store.source_teacher_name = source_teacher_name
            end
          end
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
