module Teachers
  class ReplaceTRN
    def initialize(teacher:)
      @teacher = teacher
    end

    def replace!
      return unless merge_required?
      return unless only_one_teacher_with_redirected_trn?

      ActiveRecord::Base.transaction do
        old_trn = teacher.trn
        new_trn = teacher.trs_redirected_to

        teacher.update!(
          trn: new_trn,
          trs_redirected_to: nil,
          trs_response: "ok"
        )

        record_teacher_trn_replaced_event!(old_trn, new_trn)
      end

      Teachers::SyncTeacherWithTRSJob.perform_later(teacher:)
    end

  private

    attr_reader :teacher

    def merge_required?
      teacher.trs_response == "permanent_redirect" && teacher.trs_redirected_to.present?
    end

    def only_one_teacher_with_redirected_trn?
      Teacher.where(trs_redirected_to: teacher.trs_redirected_to).one?
    end

    def author
      Events::SystemAuthor.new
    end

    def record_teacher_trn_replaced_event!(old_trn, new_trn)
      Events::Record.record_teacher_trn_replaced_event!(teacher:, author:, old_trn:, new_trn:)
    end
  end
end
