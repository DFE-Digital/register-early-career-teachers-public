module Admin
  module Teachers
    module ChangeTRNWizard
      class Wizard < ApplicationWizard
        class TeacherNotDeactivatedError < StandardError; end
        class MergeProposalChangedError < StandardError; end
        class IneligibleForReplacementError < StandardError; end
        class IneligibleForMergeError < StandardError; end
        class MergeDestinationChangedError < StandardError; end

        attr_accessor :store, :teacher_id, :author

        steps do
          [{
            enter_trn: EnterTRNStep,
            cannot_use_trn: CannotUseTRNStep,
            merge_preview: MergePreviewStep,
            confirm: ConfirmStep,
            confirmation: ConfirmationStep
          }]
        end

        def self.step?(step_name)
          steps.first[step_name].present?
        end

        def allowed_steps
          return [:confirmation] if store.records_processed.present?
          return [] unless teacher.trs_response_gone?

          allowed = %i[cannot_use_trn enter_trn]
          return allowed if store.trn.blank?

          if merge_proposed?
            allowed << :merge_preview
            allowed << :confirm if store.merge_previewed
          else
            allowed << :confirm
          end

          allowed
        end

        def teacher
          @teacher ||= Teacher.find(teacher_id)
        end

        def teacher_name
          return store.source_teacher_name if records_merged?

          ::Teachers::Name.new(teacher).full_name
        end

        def destination
          return if replace_proposed?

          @destination ||= Teacher
            .where.not(id: teacher_id)
            .find_by!(
              id: store.destination_teacher_id,
              trn: store.trn
            )
        rescue ActiveRecord::RecordNotFound
          raise MergeDestinationChangedError
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

        def merge_proposed?
          store.destination_teacher_id.present?
        end

        def ineligible_for_merge?
          merge_proposed? && !eligibility.can_be_merged?
        end

        def records_merged?
          store.records_processed == "merged"
        end

        def update!
          teacher.with_lock do
            with_destination_lock do
              raise TeacherNotDeactivatedError unless teacher.trs_response_gone?
              raise MergeProposalChangedError unless destination_trn_matches_proposal?
              raise IneligibleForMergeError if merge_proposed? && !eligible?
              raise IneligibleForReplacementError if replace_proposed? && !eligible?

              old_trn = teacher.trn
              source_teacher_name = teacher_name

              merge_proposed? ? merge! : replace!

              store.old_trn = old_trn
              store.source_teacher_name = source_teacher_name
            end
          end
        end

      private

        def destination_trn_matches_proposal?
          return true unless merge_proposed?

          store.trn.present? && destination.trn == store.trn
        end

        def with_destination_lock(&block)
          if merge_proposed?
            destination.with_lock(&block)
          else
            yield
          end
        end

        def merge!
          ::Teachers::TRN::Merge.new(teacher:, new_trn: store.trn, author:).merge!

          store.records_processed = "merged"
        end

        def replace!
          ::Teachers::TRN::Replace.new(teacher:, new_trn: store.trn, author:).replace!

          store.records_processed = "replaced"
        end

        def replace_proposed?
          !merge_proposed?
        end

        def eligible?
          if merge_proposed?
            eligibility.can_be_merged?
          else
            eligibility.can_be_replaced?
          end
        end

        def eligibility
          ::Teachers::TRN::Eligibility.new(teacher:, new_trn: store.trn)
        end

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
