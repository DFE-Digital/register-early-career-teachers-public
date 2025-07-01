module Admin
  class CheckTeacher
    attr_reader :pending_induction_submission, :author, :teacher

    def initialize(pending_induction_submission:, author:)
      @pending_induction_submission = pending_induction_submission
      @author = author
    end

    def import_teacher!
      pending_induction_submission.assign_attributes(confirmed: true, confirmed_at: Time.zone.now)

      return false unless pending_induction_submission.valid?(:check_ect)

      begin
        ActiveRecord::Base.transaction do
          create_teacher!
          record_import_event!
          pending_induction_submission.destroy!
        end
        true
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
        false
      end
    end

  private

    def create_teacher!
      @teacher = Teacher.create!(
        trn: pending_induction_submission.trn,
        trs_first_name: pending_induction_submission.trs_first_name,
        trs_last_name: pending_induction_submission.trs_last_name,
        trs_qts_awarded_on: pending_induction_submission.trs_qts_awarded_on,
        trs_qts_status_description: pending_induction_submission.trs_qts_status_description,
        trs_induction_status: pending_induction_submission.trs_induction_status,
        trs_initial_teacher_training_provider_name: pending_induction_submission.trs_initial_teacher_training_provider_name,
        trs_initial_teacher_training_end_date: pending_induction_submission.trs_initial_teacher_training_end_date,
        trs_data_last_refreshed_at: Time.zone.now
      )
    end

    def record_import_event!
      Events::Record.teacher_imported_from_trs_event!(
        author:,
        teacher:
      )
    end
  end
end
