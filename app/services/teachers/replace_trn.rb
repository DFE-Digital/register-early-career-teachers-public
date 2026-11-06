module Teachers
  class ReplaceTRN
    class TeacherNotDeactivatedError < StandardError; end
    class TRNUnchangedError < StandardError; end
    class RedirectedTeacherExistsError < StandardError; end

    def initialize(teacher:, author: Events::SystemAuthor.new)
      @teacher = teacher
      @author = author
    end

    def replace!
      teacher.with_lock do
        return unless merge_required?
        return unless only_one_teacher_with_redirected_trn?

        replace_trn!(new_trn: teacher.trs_redirected_to)
      end

      Teachers::SyncTeacherWithTRSJob.perform_later(teacher:)
    end

    def replace_deactivated!(new_trn:)
      teacher.with_lock do
        raise TeacherNotDeactivatedError unless teacher.trs_response_gone?
        raise TRNUnchangedError if new_trn == teacher.trn
        raise RedirectedTeacherExistsError if another_teacher_redirects_to?(new_trn)

        replace_trn!(new_trn:)
      end

      Teachers::SyncTeacherWithTRSJob.perform_later(teacher:)
    end

  private

    attr_reader :teacher, :author

    def replace_trn!(new_trn:)
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

    def another_teacher_redirects_to?(trn)
      Teacher.where.not(id: teacher.id)
        .exists?(trs_redirected_to: trn)
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
