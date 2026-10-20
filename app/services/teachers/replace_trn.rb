module Teachers
  class ReplaceTRN
    class TeacherNotDeactivated < StandardError; end

    def initialize(teacher:)
      @teacher = teacher
    end

    def replace!
      return unless merge_required?
      return unless only_one_teacher_with_redirected_trn?

      replace_trn!(
        new_trn: teacher.trs_redirected_to,
        author: Events::SystemAuthor.new
      )

      Teachers::SyncTeacherWithTRSJob.perform_later(teacher:)
    end

    def replace_deactivated!(new_trn:, author:)
      teacher.with_lock do
        raise TeacherNotDeactivated unless teacher.trs_response_gone?

        replace_trn!(new_trn:, author:)
      end

      Teachers::SyncTeacherWithTRSJob.perform_later(teacher:)
    end

  private

    attr_reader :teacher

    def replace_trn!(new_trn:, author:)
      ActiveRecord::Base.transaction do
        old_trn = teacher.trn

        teacher.update!(
          trn: new_trn,
          trs_redirected_to: nil,
          trs_response: "ok"
        )

        Events::Record.record_teacher_trn_replaced_event!(
          teacher:,
          author:,
          old_trn:,
          new_trn:
        )
      end
    end

    def merge_required?
      teacher.trs_response == "permanent_redirect" &&
        teacher.trs_redirected_to.present?
    end

    def only_one_teacher_with_redirected_trn?
      Teacher.where(trs_redirected_to: teacher.trs_redirected_to).one?
    end
  end
end
