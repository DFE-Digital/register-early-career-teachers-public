module Teachers
  class ReplaceTRN
    class CircularRedirectError < StandardError; end

    def initialize(teacher:)
      @teacher = teacher
    end

    def replace!
      return unless merge_required?
      return unless only_one_teacher_with_redirected_trn?
      raise CircularRedirectError if circular_redirect?

      ActiveRecord::Base.transaction do
        old_trn = teacher.trn
        new_trn = teacher.trs_redirected_to

        teacher.trn = new_trn
        teacher.trs_redirected_to = nil
        teacher.trs_response = "ok"

        return unless teacher.valid?

        teacher.save!

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
      candidates.size == 1
    end

    def candidates
      @candidates ||= Teacher.where(trs_redirected_to: teacher.trs_redirected_to).take(2)
    end

    def circular_redirect?
      replacement_teacher = Teacher.find_by(trn: teacher.trs_redirected_to)

      return false unless replacement_teacher&.trs_response == "permanent_redirect"

      replacement_teacher.trs_redirected_to == teacher.trn
    end

    def author
      Events::SystemAuthor.new
    end

    def record_teacher_trn_replaced_event!(old_trn, new_trn)
      Events::Record.record_teacher_trn_replaced_event!(teacher:, author:, old_trn:, new_trn:)
    end
  end
end
