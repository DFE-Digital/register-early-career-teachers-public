module Teachers
  # Update a Teacher with TRS data using Teachers::Manage
  module Manageable
    extend ActiveSupport::Concern

  private

    # @return [TRS::Teacher, PendingInductionSubmission]
    def trs_data
      raise NotImplementedError, "Define trs_data to return an object that responds to the required TRS attributes"
    end

    # @return [Teachers::Manage] defaults to acting on behalf of the system
    def manage_teacher
      @manage_teacher ||= Teachers::Manage.system_update(teacher:)
    end

    # @return [Boolean]
    def update_name!
      manage_teacher.update_name!(
        trs_first_name: trs_data.trs_first_name,
        trs_last_name: trs_data.trs_last_name
      )
    end

    # @return [Boolean]
    def update_trs_induction_status!
      manage_teacher.update_trs_induction_status!(
        trs_induction_status: trs_data.trs_induction_status,
        trs_induction_start_date: trs_data.trs_induction_start_date,
        trs_induction_completed_date: trs_data.trs_induction_completed_date
      )
    end

    # @return [Boolean]
    def update_trs_attributes!
      manage_teacher.update_trs_attributes!(
        trs_qts_status_description: trs_data.trs_qts_status_description,
        trs_qts_awarded_on: trs_data.trs_qts_awarded_on,
        trs_initial_teacher_training_provider_name: trs_data.trs_initial_teacher_training_provider_name,
        trs_initial_teacher_training_end_date: trs_data.trs_initial_teacher_training_end_date,
        trs_data_last_refreshed_at: Time.zone.now
      )
    end

    # @return [Boolean]
    def mark_teacher_as_deactivated!
      manage_teacher.mark_teacher_as_deactivated!(
        trs_data_last_refreshed_at: Time.zone.now
      )
    end

    # @return [Boolean]
    def mark_teacher_as_not_found!
      manage_teacher.mark_teacher_as_not_found!(
        trs_data_last_refreshed_at: Time.zone.now
      )
    end
  end
end
