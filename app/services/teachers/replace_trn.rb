module Teachers
  class ReplaceTRN
    def initialize(teacher:, new_trn: nil, author: nil)
      @teacher = teacher
      @author = author || Events::SystemAuthor.new
      @new_trn = new_trn
    end

    def replace!
      teacher.with_lock do
        return unless Teachers::MergeTRN::Eligibility.new(teacher:, new_trn: @new_trn).can_be_replaced?

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

      Teachers::SyncTeacherWithTRSJob.perform_later(teacher:)
    end

  private

    attr_reader :teacher, :author

    def new_trn
      @new_trn ||= teacher.trs_redirected_to
    end
  end
end
